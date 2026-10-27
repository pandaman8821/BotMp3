package com.example.botmp3.ui.fragments;

import android.app.Activity;
import android.os.Bundle;
import android.widget.FrameLayout;

/**
 * Actividad nativa que aloja el ecualizador.
 *
 * Se abre desde Flutter con el MethodChannel "botmp3/equalizer".
 * No necesita layout XML: crea un contenedor y monta el fragmento.
 */
public class EqualizerActivity extends Activity implements EqualizerFragment.EqualizerHost {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        FrameLayout contenedor = new FrameLayout(this);
        contenedor.setId(1);
        setContentView(contenedor);

        if (savedInstanceState == null) {
            getFragmentManager()
                    .beginTransaction()
                    .replace(1, new EqualizerFragment())
                    .commit();
        }
    }

    @Override
    public void applyEqualizer(float[] gainsDb) {
        // Aqui se puede conectar el ecualizador al servicio de audio real.
        // El fragmento ya aplica el efecto nativo del framework; este metodo
        // queda listo por si tu servicio expone su propio applyEqualizer.
    }
}