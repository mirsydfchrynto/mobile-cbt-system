allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Global Namespace Auto-Fix for Legacy Plugins (AGP 8+)
subprojects {
    val fixNamespace = Action<Project> {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                if (getNamespace.invoke(android) == null) {
                    val generatedNamespace = "com.okeybimbel.autofix.${name.replace("-", "_")}"
                    setNamespace.invoke(android, generatedNamespace)
                    println("Applied namespace fix for: $name -> $generatedNamespace")
                }
            } catch (e: Exception) {
                // Ignore if methods are missing or other issues
            }
        }
    }

    if (state.executed) {
        fixNamespace.execute(this)
    } else {
        afterEvaluate {
            fixNamespace.execute(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
