# flutter_tts 4.2.5

Upstream: https://github.com/dlutton/flutter_tts (pub.dev 4.2.5).
MIT license retained in LICENSE. Runtime sources are unchanged.

This app uses AGP 9.1 built-in Kotlin. In android/build.gradle the legacy
Kotlin plugin/classpath and explicit Kotlin stdlib dependency were removed;
kotlinOptions was migrated to kotlin.compilerOptions with JVM 11 retained.
This local package targets the app's AGP 9 setup, not older AGP consumers.
Replace this fork with an upstream package when built-in Kotlin is supported.
