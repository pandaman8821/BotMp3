package com.example.botmp3.ui.fragments;

import android.app.Fragment;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.os.Bundle;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.PopupMenu;
import android.widget.ScrollView;
import android.widget.SeekBar;
import android.widget.TextView;

import java.util.Locale;

/**
 * Pantalla de ecualizador de 5 bandas.
 *
 * Usa la API del framework {@link android.media.audiofx.Equalizer} (no necesita
 * dependencias externas) y dibuja el grafico con un View propio y Canvas, que es
 * la opcion mas ligera: no crea una vista por barra.
 *
 * Los cambios se guardan en SharedPreferences al instante y se aplican en vivo.
 * Si el audio esta pausado no pasa nada: los valores quedan guardados y se
 * aplicaran en cuanto empiece a sonar.
 */
public class EqualizerFragment extends Fragment {

    private static final String ARG_SESION = "session";

    private int sesionAudio = 0;

    /** Crea el fragmento con el id de sesion de audio del motor. */
    public static EqualizerFragment nuevaInstancia(int sesionAudio) {
        EqualizerFragment fragmento = new EqualizerFragment();
        Bundle argumentos = new Bundle();
        argumentos.putInt(ARG_SESION, sesionAudio);
        fragmento.setArguments(argumentos);
        return fragmento;
    }

    // ------------------------------------------------------------------ constantes

    private static final String PREFS = "botmp3_equalizer";
    private static final String CLAVE_GANANCIAS = "gains_db";
    private static final String CLAVE_APLASTAR = "aplastar";

    private static final int BANDAS = 5;
    private static final int DB_MIN = -12;
    private static final int DB_MAX = 12;
    private static final int PASO_MAX = DB_MAX - DB_MIN;
    private static final float DB_MAX_F = 12f;

    /** Etiquetas de frecuencia de cada banda. */
    private static final String[] FRECUENCIAS = {"63 Hz", "250 Hz", "1 kHz", "4 kHz", "16 kHz"};

    /** Presets rapidos (valores en dB para las 5 bandas). */
    private static final String[] PRESETS_NOMBRES = {"Rock", "Pop", "Jazz", "Clasico"};
    private static final float[][] PRESETS_VALORES = {
            {+5f, +3f, 0f, +2f, +4f},   // Rock
            {-2f, +1f, +4f, +3f, -1f},  // Pop
            {+3f, +1f, 0f, +2f, +2f},   // Jazz
            {+2f, +2f, -1f, +3f, +4f}   // Clasico
    };

    /** Preset "Aplastar": graves arriba, medios abajo. */
    private static final float[] APLASTAR_VALORES = {+6f, +6f, -3f, -3f, 0f};

    // ------------------------------------------------------------------ estado

    private final float[] gananciasDb = new float[BANDAS];
    private boolean aplastarActivo = false;

    private EqBarsView barras;
    private final SeekBar[] sliders = new SeekBar[BANDAS];
    private TextView estado;
    private Button botonAplastar;

    private SharedPreferences prefs;
    private android.media.audiofx.Equalizer ecualizadorNativo;
    private boolean actualizandoSliders = false;

    /** Implementa esto en tu actividad o servicio para aplicar el EQ en vivo. */
    public interface EqualizerHost {
        /**
         * @param gainsDb ganancias de las 5 bandas en dB (-12 a +12).
         */
        void applyEqualizer(float[] gainsDb);
    }

    // ------------------------------------------------------------------ ciclo de vida

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        final Context contexto = getActivity();
        if (getArguments() != null) {
            sesionAudio = getArguments().getInt(ARG_SESION, 0);
        }
        prefs = contexto.getSharedPreferences(PREFS, Context.MODE_PRIVATE);

        ScrollView scroll = new ScrollView(contexto);
        scroll.setFillViewport(true);
        scroll.setBackgroundColor(Color.parseColor("#0F1522"));

        LinearLayout root = new LinearLayout(contexto);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(16), dp(18), dp(16), dp(24));
        scroll.addView(root, new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        // ---- Titulo grande
        TextView titulo = new TextView(contexto);
        titulo.setText("Ecualizador");
        titulo.setTextColor(Color.parseColor("#FFFFFF"));
        titulo.setTextSize(26f);
        titulo.setGravity(Gravity.START);
        root.addView(titulo);

        TextView subtitulo = new TextView(contexto);
        subtitulo.setText("Ajusta cada banda de -12 dB a +12 dB");
        subtitulo.setTextColor(Color.parseColor("#AFC0D6"));
        subtitulo.setTextSize(13f);
        LinearLayout.LayoutParams subLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        subLp.topMargin = dp(2);
        root.addView(subtitulo, subLp);

        // ---- Grafico de barras (Canvas)
        barras = new EqBarsView(contexto);
        LinearLayout.LayoutParams barrasLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(170));
        barrasLp.topMargin = dp(14);
        root.addView(barras, barrasLp);

        // ---- Sliders de las 5 bandas
        for (int i = 0; i < BANDAS; i++) {
            final int banda = i;

            LinearLayout fila = new LinearLayout(contexto);
            fila.setOrientation(LinearLayout.HORIZONTAL);
            fila.setGravity(Gravity.CENTER_VERTICAL);
            LinearLayout.LayoutParams filaLp = new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            filaLp.topMargin = dp(8);
            root.addView(fila, filaLp);

            TextView etiqueta = new TextView(contexto);
            etiqueta.setText(FRECUENCIAS[i]);
            etiqueta.setTextColor(Color.parseColor("#E6ECF5"));
            etiqueta.setTextSize(13f);
            etiqueta.setGravity(Gravity.CENTER);
            fila.addView(etiqueta, new LinearLayout.LayoutParams(dp(64),
                    ViewGroup.LayoutParams.WRAP_CONTENT));

            SeekBar slider = new SeekBar(contexto);
            slider.setMax(PASO_MAX);
            slider.setProgress(DB_MAX);
            slider.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
                @Override
                public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                    if (actualizandoSliders) return;
                    gananciasDb[banda] = progress + DB_MIN;
                    aplicarYGuardar();
                }

                @Override
                public void onStartTrackingTouch(SeekBar seekBar) { }

                @Override
                public void onStopTrackingTouch(SeekBar seekBar) { }
            });
            slider.setLayoutParams(new LinearLayout.LayoutParams(0,
                    ViewGroup.LayoutParams.WRAP_CONTENT, 1f));
            fila.addView(slider);
            sliders[i] = slider;
        }

        // ---- Texto de ganancia actual
        estado = new TextView(contexto);
        estado.setTextColor(Color.parseColor("#34D399"));
        estado.setTextSize(14f);
        LinearLayout.LayoutParams estadoLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        estadoLp.topMargin = dp(14);
        root.addView(estado, estadoLp);

        // ---- Botones de accion
        LinearLayout acciones = new LinearLayout(contexto);
        acciones.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams accionesLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        accionesLp.topMargin = dp(12);
        root.addView(acciones, accionesLp);

        Button reset = crearBoton(contexto, "Reset");
        reset.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                for (int i = 0; i < BANDAS; i++) gananciasDb[i] = 0f;
                aplastarActivo = false;
                if (botonAplastar != null) botonAplastar.setText("Aplastar");
                sincronizarSliders();
                aplicarYGuardar();
            }
        });
        acciones.addView(reset, peso());

        botonAplastar = crearBoton(contexto, "Aplastar");
        botonAplastar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                aplastarActivo = !aplastarActivo;
                if (aplastarActivo) {
                    System.arraycopy(APLASTAR_VALORES, 0, gananciasDb, 0, BANDAS);
                } else {
                    for (int i = 0; i < BANDAS; i++) gananciasDb[i] = 0f;
                }
                botonAplastar.setText(aplastarActivo ? "Aplastar: ON" : "Aplastar");
                sincronizarSliders();
                aplicarYGuardar();
            }
        });
        acciones.addView(botonAplastar, peso());

        Button presets = crearBoton(contexto, "Presets");
        presets.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mostrarPresets(v);
            }
        });
        acciones.addView(presets, peso());

        // ---- Carga de los valores guardados
        cargar();

        return scroll;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        liberarEcualizador();
    }

    // ------------------------------------------------------------------ presets

    private void mostrarPresets(View ancla) {
        PopupMenu menu = new PopupMenu(getActivity(), ancla);
        for (int i = 0; i < PRESETS_NOMBRES.length; i++) {
            menu.getMenu().add(0, i, i, PRESETS_NOMBRES[i]);
        }
        menu.setOnMenuItemClickListener(new PopupMenu.OnMenuItemClickListener() {
            @Override
            public boolean onMenuItemClick(MenuItem item) {
                int indice = item.getItemId();
                if (indice >= 0 && indice < PRESETS_VALORES.length) {
                    System.arraycopy(PRESETS_VALORES[indice], 0, gananciasDb, 0, BANDAS);
                    aplastarActivo = false;
                    if (botonAplastar != null) botonAplastar.setText("Aplastar");
                    sincronizarSliders();
                    aplicarYGuardar();
                }
                return true;
            }
        });
        menu.show();
    }

    // ------------------------------------------------------------------ aplicar y guardar

    /** Pinta el grafico, actualiza el texto, guarda y aplica al motor. */
    private void aplicarYGuardar() {
        if (barras != null) barras.setGanancias(gananciasDb);
        if (estado != null) estado.setText(descripcionGanancias());
        guardar();
        aplicarAlMotor();
    }

    private String descripcionGanancias() {
        float suma = 0f;
        for (float g : gananciasDb) suma += g;
        float media = suma / BANDAS;
        return String.format(Locale.getDefault(),
                "Ganancia actual: %s%.1f dB  ·  63 Hz %s%.0f · 16 kHz %s%.0f",
                signo(media), Float.valueOf(media),
                signo(gananciasDb[0]), Float.valueOf(gananciasDb[0]),
                signo(gananciasDb[BANDAS - 1]), Float.valueOf(gananciasDb[BANDAS - 1]));
    }

    private String signo(float valor) {
        return valor >= 0 ? "+" : "";
    }

    private void guardar() {
        if (prefs == null) return;
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < BANDAS; i++) {
            if (i > 0) sb.append(',');
            sb.append(gananciasDb[i]);
        }
        prefs.edit()
                .putString(CLAVE_GANANCIAS, sb.toString())
                .putBoolean(CLAVE_APLASTAR, aplastarActivo)
                .apply();
    }

    private void cargar() {
        if (prefs == null) return;
        String guardadas = prefs.getString(CLAVE_GANANCIAS, null);
        if (guardadas != null && !guardadas.isEmpty()) {
            String[] partes = guardadas.split(",");
            for (int i = 0; i < BANDAS && i < partes.length; i++) {
                try {
                    float valor = Float.parseFloat(partes[i].trim());
                    gananciasDb[i] = Math.max(-DB_MAX_F, Math.min(DB_MAX_F, valor));
                } catch (NumberFormatException ignorado) {
                    gananciasDb[i] = 0f;
                }
            }
        }
        aplastarActivo = prefs.getBoolean(CLAVE_APLASTAR, false);
        if (botonAplastar != null) {
            botonAplastar.setText(aplastarActivo ? "Aplastar: ON" : "Aplastar");
        }
        sincronizarSliders();
        aplicarYGuardar();
    }

    /** Mueve los SeekBar sin disparar sus oyentes. */
    private void sincronizarSliders() {
        actualizandoSliders = true;
        for (int i = 0; i < BANDAS; i++) {
            if (sliders[i] == null) continue;
            int progreso = Math.round(gananciasDb[i]) - DB_MIN;
            sliders[i].setProgress(Math.max(0, Math.min(PASO_MAX, progreso)));
        }
        actualizandoSliders = false;
    }

    /** Aplica el EQ de verdad: gancho del servicio + API nativa del framework. */
    private void aplicarAlMotor() {
        // 1) Gancho del servicio (si existe). Se llama siempre, suene o no.
        try {
            if (getActivity() instanceof EqualizerHost) {
                ((EqualizerHost) getActivity()).applyEqualizer(gananciasDb.clone());
            }
        } catch (Throwable ignorado) {
            // El ecualizador es opcional: nunca debe romper la pantalla.
        }

        // 2) Ecualizador nativo del framework sobre la salida global (sesion 0).
        try {
            if (ecualizadorNativo == null) {
                ecualizadorNativo = new android.media.audiofx.Equalizer(0, sesionAudio);
                ecualizadorNativo.setEnabled(true);
            }
            short numeroBandas = ecualizadorNativo.getNumberOfBands();
            short[] rango = ecualizadorNativo.getBandLevelRange();
            for (short b = 0; b < numeroBandas && b < BANDAS; b++) {
                int indice = (numeroBandas <= 1)
                        ? 0
                        : (int) Math.round(b * (BANDAS - 1) / (double) (numeroBandas - 1));
                float db = gananciasDb[indice];
                short nivel = (short) (db * 100f);
                if (nivel < rango[0]) nivel = rango[0];
                if (nivel > rango[1]) nivel = rango[1];
                ecualizadorNativo.setBandLevel(b, nivel);
            }
        } catch (Throwable ignorado) {
            // Algunos equipos no permiten efectos globales: se ignora.
        }
    }

    private void liberarEcualizador() {
        try {
            if (ecualizadorNativo != null) {
                ecualizadorNativo.setEnabled(false);
                ecualizadorNativo.release();
                ecualizadorNativo = null;
            }
        } catch (Throwable ignorado) {
            // Nada que hacer.
        }
    }

    // ------------------------------------------------------------------ utilidades de UI

    private Button crearBoton(Context contexto, String texto) {
        Button boton = new Button(contexto);
        boton.setText(texto);
        boton.setAllCaps(false);
        boton.setTextColor(Color.parseColor("#0F1522"));
        boton.setBackgroundColor(Color.parseColor("#34D399"));
        boton.setTextSize(13f);
        return boton;
    }

    private LinearLayout.LayoutParams peso() {
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0,
                ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        lp.setMargins(dp(4), 0, dp(4), 0);
        return lp;
    }

    private int dp(float valor) {
        return Math.round(valor * getResources().getDisplayMetrics().density);
    }

    // ------------------------------------------------------------------ grafico de barras

    /** Grafico de barras del ecualizador, dibujado con Canvas. */
    private static class EqBarsView extends View {

        private final Paint pincel = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint pincelBorde = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint pincelTexto = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final RectF rect = new RectF();
        private final float[] ganancias = new float[BANDAS];

        EqBarsView(Context contexto) {
            super(contexto);
            pincelBorde.setStyle(Paint.Style.STROKE);
            pincelBorde.setColor(Color.parseColor("#2A3850"));
            pincelBorde.setStrokeWidth(1f);
            pincelTexto.setColor(Color.parseColor("#8FA3BF"));
            pincelTexto.setTextSize(11f * contexto.getResources().getDisplayMetrics().density);
            pincelTexto.setTextAlign(Paint.Align.CENTER);
        }

        void setGanancias(float[] valores) {
            for (int i = 0; i < BANDAS; i++) {
                ganancias[i] = i < valores.length ? valores[i] : 0f;
            }
            invalidate();
        }

        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            float ancho = getWidth();
            float alto = getHeight();
            float margenTexto = 18f * getResources().getDisplayMetrics().density;
            float disponible = alto - margenTexto;
            float centro = disponible / 2f;

            pincelBorde.setColor(Color.parseColor("#3C5175"));
            canvas.drawLine(0, centro, ancho, centro, pincelBorde);
            pincelBorde.setColor(Color.parseColor("#2A3850"));

            float espacio = ancho / (float) BANDAS;
            float anchoBarra = espacio * 0.5f;

            for (int i = 0; i < BANDAS; i++) {
                float x = i * espacio + (espacio - anchoBarra) / 2f;
                float valor = Math.max(-DB_MAX_F, Math.min(DB_MAX_F, ganancias[i]));
                float proporcion = valor / DB_MAX_F;
                float alturaBarra = Math.abs(proporcion) * centro;

                if (valor >= 0) {
                    rect.set(x, centro - alturaBarra, x + anchoBarra, centro);
                    pincel.setColor(Color.parseColor("#34D399"));
                } else {
                    rect.set(x, centro, x + anchoBarra, centro + alturaBarra);
                    pincel.setColor(Color.parseColor("#F87171"));
                }
                canvas.drawRoundRect(rect, anchoBarra / 3f, anchoBarra / 3f, pincel);
                canvas.drawRoundRect(rect, anchoBarra / 3f, anchoBarra / 3f, pincelBorde);

                canvas.drawText(FRECUENCIAS[i], x + anchoBarra / 2f, alto - 2f, pincelTexto);
            }
        }
    }
}