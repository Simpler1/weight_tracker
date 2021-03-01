package com.routineapps.weight_tracker;

import android.content.Intent;
import android.os.Bundle;
import androidx.annotation.NonNull;
import com.google.android.gms.actions.NoteIntents;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "app.channel.shared.data";
    String savedNote;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        Intent intent = getIntent();
        String action = intent.getAction();
        String type = intent.getType();

        if (NoteIntents.ACTION_CREATE_NOTE.equals(action) && type != null) {
            if ("text/plain".equals(type)) {
                handleSendText(intent);
            }
        }

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    if (call.method.contentEquals("getSavedNote")) {
                        result.success(savedNote);
                        savedNote = null;
                    }
                }
            );
    }


    void handleSendText(Intent intent) {
        savedNote = intent.getStringExtra(Intent.EXTRA_TEXT);
    }
}
        