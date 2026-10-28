package com.example.botmp3.ui.fragments;

import android.app.Activity;
import android.os.Bundle;
import android.widget.FrameLayout;

/**
 * Actividad nativa que aloja el ecualizador.
 *
 * Recibe por Intent el id de sesion de audio del motor (extra "session") y lo
 * pasa al fragmento: asi el efecto se aplica a la reproduccion real y no a la
 * salida global (que Android 10+ restringe).
 */
public class EqualizerActivity extends Activity implements EqualizerFragment.EqualizerHost {

    public static final String EXTRA_SESION = "session";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        FrameLayout contenedor = new FrameLayout(this);
        contenedor.setId(1);
        setContentView(contenedor);

        if (savedInstanceState == null) {
            int sesion = (getIntent() != null)
                    ? getIntent().getIntExtra(EXTRA_SESION, 0)
                    : 0;
            EqualizerFragment fragmento = EqualizerFragment.nuevaInstancia(sesion);
            getFragmentManager()
                    .beginTransaction()
                    .replace(1, fragmento)
                    .commit();
        }
    }

    @Override
    public void applyEqualizer(float[] gainsDb) {
        // El fragmento ya aplica el efecto nativo sobre la sesion del motor.
        // Este gancho queda disponible por si el servicio quiere hacer algo mas.
    }
}