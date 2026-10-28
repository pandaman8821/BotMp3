package com.example.botmp3.ui.fragments;

import android.app.Fragment;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.SeekBar;
import android.widget.TextView;

import java.util.Locale;

/**
 * Ecualizador de 5 bandas con interfaz moderna.
 *
 * - Cabecera con degradado y la ganancia actual en una "pildora".
 * - Grafico de barras propio (Canvas) con rejilla de dB, valores y barras con
 *   degradado; se dibuja solo cuando cambia algo, asi no gasta bateria.
 * - Cada banda en su tarjeta redondeada con un SeekBar.
 * - Presets como chips y accion "Aplastar" destacada.
 *
 * Se aplica a la sesion de audio del motor (recibida por argumentos) y se guarda
 * en SharedPreferences en cada cambio.
 */
public class EqualizerFragment extends Fragment {

    private static final String PREFS = "botmp3_equalizer";
    private static final String CLAVE_GANANCIAS = "gains_db";
    private static final String CLAVE_APLASTAR = "aplastar";
    private static final String ARG_SESION = "session";

    private static final int BANDAS = 5;
    private static final int DB_MIN = -12;
    private static final int DB_MAX = 12;
    private static final int PASO_MAX = DB_MAX - DB_MIN;
    private static final float DB_MAX_F = 12f;

    private static final String[] FRECUENCIAS = {"63 Hz", "250 Hz", "1 kHz", "4 kHz", "16 kHz"};

    private static final String[] PRESETS_NOMBRES = {"Rock", "Pop", "Jazz", "Clásico"};
    private static final float[][] PRESETS_VALORES = {
            {+5f, +3f, 0f, +2f, +4f},
            {-2f, +1f, +4f, +3f, -1f},
            {+3f, +1f, 0f, +2f, +2f},
            {+2f, +2f, -1f, +3f, +4f}
    };
    private static final float[] APLASTAR_VALORES = {+6f, +6f, -3f, -3f, 0f};

    // Colores de la app
    private static final int FONDO = Color.parseColor("#0B111C");
    private static final int TARJETA = Color.parseColor("#111A29");
    private static final int BORDE = Color.parseColor("#22324A");
    private static final int VERDE = Color.parseColor("#34D399");
    private static final int ROJO = Color.parseColor("#F87171");
    private static final int TEXTO = Color.parseColor("#F2F6FC");
    private static final int TEXTO_SUAVE = Color.parseColor("#9DB0C9");

    private final float[] gananciasDb = new float[BANDAS];
    private boolean aplastarActivo = false;
    private int sesionAudio = 0;

    private EqBarsView barras;
    private final SeekBar[] sliders = new SeekBar[BANDAS];
    private final TextView[] valores = new TextView[BANDAS];
    private TextView pildoraGanancia;
    private Button botonAplastar;

    private SharedPreferences prefs;
    private android.media.audiofx.Equalizer ecualizadorNativo;
    private boolean actualizandoSliders = false;

    /** Gancho opcional para que el servicio aplique el EQ con su propio motor. */
    public interface EqualizerHost {
        void applyEqualizer(float[] gainsDb);
    }

    /** Crea el fragmento con el id de sesion de audio del motor. */
    public static EqualizerFragment nuevaInstancia(int sesionAudio) {
        EqualizerFragment fragmento = new EqualizerFragment();
        Bundle argumentos = new Bundle();
        argumentos.putInt(ARG_SESION, sesionAudio);
        fragmento.setArguments(argumentos);
        return fragmento;
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
        scroll.setBackgroundColor(FONDO);

        LinearLayout root = new LinearLayout(contexto);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(16), dp(16), dp(16), dp(28));
        scroll.addView(root, new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        // ---- Cabecera con degradado
        LinearLayout cabecera = new LinearLayout(contexto);
        cabecera.setOrientation(LinearLayout.VERTICAL);
        cabecera.setPadding(dp(18), dp(16), dp(18), dp(16));
        GradientDrawable fondoCabecera = new GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                new int[]{Color.parseColor("#1E3A5F"), Color.parseColor("#12203A")});
        fondoCabecera.setCornerRadius(dp(22));
        cabecera.setBackground(fondoCabecera);
        root.addView(cabecera);

        TextView titulo = new TextView(contexto);
        titulo.setText("Ecualizador");
        titulo.setTextColor(TEXTO);
        titulo.setTextSize(26f);
        titulo.setTypeface(titulo.getTypeface(), android.graphics.Typeface.BOLD);
        cabecera.addView(titulo);

        TextView subtitulo = new TextView(contexto);
        subtitulo.setText("5 bandas · −12 a +12 dB · efecto en vivo");
        subtitulo.setTextColor(Color.parseColor("#B9CBE3"));
        subtitulo.setTextSize(12.5f);
        LinearLayout.LayoutParams subLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        subLp.topMargin = dp(2);
        cabecera.addView(subtitulo, subLp);

        LinearLayout filaPildora = new LinearLayout(contexto);
        filaPildora.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams pildoraLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        pildoraLp.topMargin = dp(12);
        cabecera.addView(filaPildora, pildoraLp);

        pildoraGanancia = new TextView(contexto);
        pildoraGanancia.setTextColor(VERDE);
        pildoraGanancia.setTextSize(13f);
        pildoraGanancia.setPadding(dp(12), dp(6), dp(12), dp(6));
        GradientDrawable fondoPildora = new GradientDrawable();
        fondoPildora.setColor(Color.parseColor("#0F2A22"));
        fondoPildora.setCornerRadius(dp(20));
        fondoPildora.setStroke(dp(1), Color.parseColor("#1F5C49"));
        pildoraGanancia.setBackground(fondoPildora);
        filaPildora.addView(pildoraGanancia);

        // ---- Grafico
        barras = new EqBarsView(contexto);
        LinearLayout.LayoutParams barrasLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(190));
        barrasLp.topMargin = dp(14);
        root.addView(barras, barrasLp);

        // ---- Una tarjeta por banda
        for (int i = 0; i < BANDAS; i++) {
            final int banda = i;

            LinearLayout tarjeta = new LinearLayout(contexto);
            tarjeta.setOrientation(LinearLayout.VERTICAL);
            tarjeta.setPadding(dp(14), dp(10), dp(14), dp(10));
            GradientDrawable fondoTarjeta = new GradientDrawable();
            fondoTarjeta.setColor(TARJETA);
            fondoTarjeta.setCornerRadius(dp(16));
            fondoTarjeta.setStroke(dp(1), BORDE);
            tarjeta.setBackground(fondoTarjeta);
            LinearLayout.LayoutParams tarjetaLp = new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            tarjetaLp.topMargin = dp(8);
            root.addView(tarjeta, tarjetaLp);

            LinearLayout filaTitulo = new LinearLayout(contexto);
            filaTitulo.setOrientation(LinearLayout.HORIZONTAL);
            filaTitulo.setGravity(Gravity.CENTER_VERTICAL);
            tarjeta.addView(filaTitulo);

            TextView etiqueta = new TextView(contexto);
            etiqueta.setText(FRECUENCIAS[i]);
            etiqueta.setTextColor(TEXTO);
            etiqueta.setTextSize(14f);
            etiqueta.setTypeface(etiqueta.getTypeface(), android.graphics.Typeface.BOLD);
            filaTitulo.addView(etiqueta, new LinearLayout.LayoutParams(0,
                    ViewGroup.LayoutParams.WRAP_CONTENT, 1f));

            TextView valor = new TextView(contexto);
            valor.setText("0 dB");
            valor.setTextColor(TEXTO_SUAVE);
            valor.setTextSize(13f);
            filaTitulo.addView(valor);
            valores[i] = valor;

            SeekBar slider = new SeekBar(contexto);
            slider.setMax(PASO_MAX);
            slider.setProgress(DB_MAX);
            slider.setPadding(dp(2), dp(6), dp(2), 0);
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
            tarjeta.addView(slider, new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
            sliders[i] = slider;
        }

        // ---- Chips de presets
        LinearLayout filaPresets = new LinearLayout(contexto);
        filaPresets.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams presetsLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        presetsLp.topMargin = dp(16);
        root.addView(filaPresets, presetsLp);
        for (int i = 0; i < PRESETS_NOMBRES.length; i++) {
            final int indice = i;
            TextView chip = new TextView(contexto);
            chip.setText(PRESETS_NOMBRES[i]);
            chip.setTextColor(TEXTO);
            chip.setTextSize(12.5f);
            chip.setGravity(Gravity.CENTER);
            chip.setPadding(dp(10), dp(8), dp(10), dp(8));
            GradientDrawable fondo = new GradientDrawable();
            fondo.setColor(Color.parseColor("#152134"));
            fondo.setCornerRadius(dp(18));
            fondo.setStroke(dp(1), BORDE);
            chip.setBackground(fondo);
            chip.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    System.arraycopy(PRESETS_VALORES[indice], 0, gananciasDb, 0, BANDAS);
                    aplastarActivo = false;
                    if (botonAplastar != null) botonAplastar.setText("Aplastar graves");
                    sincronizarSliders();
                    aplicarYGuardar();
                }
            });
            LinearLayout.LayoutParams chipLp = new LinearLayout.LayoutParams(0,
                    ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
            chipLp.setMargins(dp(3), 0, dp(3), 0);
            filaPresets.addView(chip, chipLp);
        }

        // ---- Botones finales
        LinearLayout acciones = new LinearLayout(contexto);
        acciones.setOrientation(LinearLayout.HORIZONTAL);
        LinearLayout.LayoutParams accionesLp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        accionesLp.topMargin = dp(14);
        root.addView(acciones, accionesLp);

        Button reset = crearBoton(contexto, "Restablecer", TEXTO, Color.parseColor("#1A2536"), BORDE);
        reset.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                for (int i = 0; i < BANDAS; i++) gananciasDb[i] = 0f;
                aplastarActivo = false;
                if (botonAplastar != null) botonAplastar.setText("Aplastar graves");
                sincronizarSliders();
                aplicarYGuardar();
            }
        });
        acciones.addView(reset, peso());

        botonAplastar = crearBoton(contexto, "Aplastar graves", Color.parseColor("#062018"), VERDE, VERDE);
        botonAplastar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                aplastarActivo = !aplastarActivo;
                if (aplastarActivo) {
                    System.arraycopy(APLASTAR_VALORES, 0, gananciasDb, 0, BANDAS);
                } else {
                    for (int i = 0; i < BANDAS; i++) gananciasDb[i] = 0f;
                }
                botonAplastar.setText(aplastarActivo ? "Aplastar: ON" : "Aplastar graves");
                sincronizarSliders();
                aplicarYGuardar();
            }
        });
        acciones.addView(botonAplastar, peso());

        cargar();
        return scroll;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        liberarEcualizador();
    }

    // ------------------------------------------------------------------ aplicar y guardar

    private void aplicarYGuardar() {
        if (barras != null) barras.setGanancias(gananciasDb);
        if (pildoraGanancia != null) pildoraGanancia.setText(descripcionGanancias());
        for (int i = 0; i < BANDAS; i++) {
            if (valores[i] != null) {
                float g = gananciasDb[i];
                valores[i].setText(String.format(Locale.getDefault(), "%s%.0f dB", signo(g), Float.valueOf(g)));
                valores[i].setTextColor(Math.abs(g) < 0.5f ? TEXTO_SUAVE : (g > 0 ? VERDE : ROJO));
            }
        }
        guardar();
        aplicarAlMotor();
    }

    private String descripcionGanancias() {
        float suma = 0f;
        for (float g : gananciasDb) suma += g;
        float media = suma / BANDAS;
        return String.format(Locale.getDefault(), "Ganancia actual %s%.1f dB", signo(media), Float.valueOf(media));
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
        prefs.edit().putString(CLAVE_GANANCIAS, sb.toString())
                .putBoolean(CLAVE_APLASTAR, aplastarActivo).apply();
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
            botonAplastar.setText(aplastarActivo ? "Aplastar: ON" : "Aplastar graves");
        }
        sincronizarSliders();
        aplicarYGuardar();
    }

    private void sincronizarSliders() {
        actualizandoSliders = true;
        for (int i = 0; i < BANDAS; i++) {
            if (sliders[i] == null) continue;
            int progreso = Math.round(gananciasDb[i]) - DB_MIN;
            sliders[i].setProgress(Math.max(0, Math.min(PASO_MAX, progreso)));
        }
        actualizandoSliders = false;
    }

    private void aplicarAlMotor() {
        try {
            if (getActivity() instanceof EqualizerHost) {
                ((EqualizerHost) getActivity()).applyEqualizer(gananciasDb.clone());
            }
        } catch (Throwable ignorado) { }
        try {
            if (ecualizadorNativo == null) {
                ecualizadorNativo = new android.media.audiofx.Equalizer(0, sesionAudio);
                ecualizadorNativo.setEnabled(true);
            }
            short numeroBandas = ecualizadorNativo.getNumberOfBands();
            short[] rango = ecualizadorNativo.getBandLevelRange();
            for (short b = 0; b < numeroBandas && b < BANDAS; b++) {
                int indice = (numeroBandas <= 1) ? 0
                        : (int) Math.round(b * (BANDAS - 1) / (double) (numeroBandas - 1));
                short nivel = (short) (gananciasDb[indice] * 100f);
                if (nivel < rango[0]) nivel = rango[0];
                if (nivel > rango[1]) nivel = rango[1];
                ecualizadorNativo.setBandLevel(b, nivel);
            }
        } catch (Throwable ignorado) { }
    }

    private void liberarEcualizador() {
        try {
            if (ecualizadorNativo != null) {
                ecualizadorNativo.setEnabled(false);
                ecualizadorNativo.release();
                ecualizadorNativo = null;
            }
        } catch (Throwable ignorado) { }
    }

    // ------------------------------------------------------------------ utilidades

    private Button crearBoton(Context contexto, String texto, int colorTexto, int colorFondo, int colorBorde) {
        Button boton = new Button(contexto);
        boton.setText(texto);
        boton.setAllCaps(false);
        boton.setTextColor(colorTexto);
        boton.setTextSize(13f);
        GradientDrawable fondo = new GradientDrawable();
        fondo.setColor(colorFondo);
        fondo.setCornerRadius(dp(14));
        fondo.setStroke(dp(1), colorBorde);
        boton.setBackground(fondo);
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

    // ------------------------------------------------------------------ grafico

    /** Grafico con rejilla de dB, valores y barras con degradado. */
    private static class EqBarsView extends View {

        private final Paint pincel = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint pincelRejilla = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint pincelTexto = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Paint pincelValor = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final RectF rect = new RectF();
        private final float[] ganancias = new float[BANDAS];

        EqBarsView(Context contexto) {
            super(contexto);
            pincel.setStyle(Paint.Style.FILL);
            pincelRejilla.setStyle(Paint.Style.STROKE);
            pincelRejilla.setColor(Color.parseColor("#1C2A3E"));
            pincelRejilla.setStrokeWidth(1f);
            pincelTexto.setColor(Color.parseColor("#7D92AD"));
            pincelTexto.setTextSize(10.5f * contexto.getResources().getDisplayMetrics().density);
            pincelTexto.setTextAlign(Paint.Align.CENTER);
            pincelValor.setColor(Color.parseColor("#E6EEF9"));
            pincelValor.setTextSize(11f * contexto.getResources().getDisplayMetrics().density);
            pincelValor.setTextAlign(Paint.Align.CENTER);
            pincelValor.setFakeBoldText(true);
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
            float pie = 16f * getResources().getDisplayMetrics().density;
            float disponible = alto - pie;
            float centro = disponible / 2f;

            // Rejilla de dB
            for (int i = -2; i <= 2; i++) {
                float y = centro - (i / 2f) * centro;
                pincelRejilla.setColor(i == 0 ? Color.parseColor("#33465F") : Color.parseColor("#1C2A3E"));
                pincelRejilla.setStrokeWidth(i == 0 ? 1.5f : 1f);
                canvas.drawLine(0, y, ancho, y, pincelRejilla);
            }

            float espacio = ancho / (float) BANDAS;
            float anchoBarra = espacio * 0.42f;

            for (int i = 0; i < BANDAS; i++) {
                float x = i * espacio + (espacio - anchoBarra) / 2f;
                float valor = Math.max(-DB_MAX_F, Math.min(DB_MAX_F, ganancias[i]));
                float alturaBarra = (Math.abs(valor) / DB_MAX_F) * centro;
                float radio = anchoBarra / 2.2f;

                boolean positivo = valor >= 0;
                rect.set(x, positivo ? centro - Math.max(alturaBarra, dp2(3)) : centro,
                        x + anchoBarra, positivo ? centro : centro + Math.max(alturaBarra, dp2(3)));

                if (positivo) {
                    pincel.setShader(new LinearGradient(0, rect.top, 0, rect.bottom,
                            Color.parseColor("#6EE7B7"), Color.parseColor("#0E9F6E"), Shader.TileMode.CLAMP));
                } else {
                    pincel.setShader(new LinearGradient(0, rect.top, 0, rect.bottom,
                            Color.parseColor("#FCA5A5"), Color.parseColor("#B91C1C"), Shader.TileMode.CLAMP));
                }
                canvas.drawRoundRect(rect, radio, radio, pincel);
                pincel.setShader(null);

                // Valor encima/debajo
                String texto = String.format(Locale.getDefault(), "%s%.0f", positivo ? "+" : "", Float.valueOf(valor));
                float yTexto = positivo ? rect.top - dp2(4) : rect.bottom + dp2(12);
                canvas.drawText(texto, x + anchoBarra / 2f, Math.max(dp2(10), Math.min(alto - pie - dp2(2), yTexto)), pincelValor);

                // Frecuencia
                canvas.drawText(FRECUENCIAS[i], x + anchoBarra / 2f, alto - dp2(2), pincelTexto);
            }
        }

        private float dp2(float v) {
            return v * getResources().getDisplayMetrics().density;
        }
    }
}