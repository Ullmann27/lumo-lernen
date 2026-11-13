package dev.ullmann.lumo;

import java.util.HashSet;
import java.util.Set;
import java.util.regex.Pattern;

/** Live Dart sessions only. A mailbox left on disk is never an authority lease. */
public final class CardsAuthorityRegistry {
    private static final Pattern TOKEN = Pattern.compile("[a-f0-9]{32}");
    private final Set<String> sessions = new HashSet<>();
    private boolean attached;

    public synchronized void attach() {
        sessions.clear();
        attached = true;
    }

    public synchronized void detach() {
        attached = false;
        sessions.clear();
    }

    public synchronized void open(String token) {
        if (token == null || !TOKEN.matcher(token).matches()) {
            throw new IllegalArgumentException("Invalid Cards table token");
        }
        if (!attached) {
            throw new IllegalStateException("Cards controller is detached");
        }
        sessions.add(token);
    }

    public synchronized void close(String token) {
        sessions.remove(token);
    }

    public synchronized boolean hasAuthority(String token) {
        return attached && sessions.contains(token);
    }
}
