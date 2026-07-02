plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.duongdo.taskflow"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.duongdo.taskflow"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    applicationVariants.configureEach {
        outputs.configureEach {
            (this as com.android.build.gradle.internal.api.BaseVariantOutputImpl).outputFileName =
                if (buildType.name == "release") "TaskFlow.apk" else "TaskFlow-${buildType.name}.apk"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

fun syncFlutterApkOutput(assembleTaskName: String, outputFileName: String) {
    tasks.named(assembleTaskName).configure {
        doLast {
            val flutterApkDir = File(rootProject.projectDir, "../build/app/outputs/flutter-apk")
            val buildType = assembleTaskName.removePrefix("assemble").lowercase()
            val variantApk = layout.buildDirectory
                .file("outputs/apk/$buildType/$outputFileName")
                .get()
                .asFile
            val legacyFlutterApk = File(
                flutterApkDir,
                "app-$buildType.apk",
            )
            val source = when {
                variantApk.exists() -> variantApk
                legacyFlutterApk.exists() -> legacyFlutterApk
                else -> return@doLast
            }
            flutterApkDir.mkdirs()
            source.copyTo(File(flutterApkDir, outputFileName), overwrite = true)
        }
    }
}

afterEvaluate {
    syncFlutterApkOutput("assembleRelease", "TaskFlow.apk")
    syncFlutterApkOutput("assembleDebug", "TaskFlow-debug.apk")
}
