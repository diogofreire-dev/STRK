// Relocaliza a pasta de build de cada módulo Android para <projeto>/build/<módulo>,
// em vez do padrão <módulo>/build. O Flutter espera este layout para conseguir
// encontrar o .apk/.aab gerado — sem isto, o Gradle compila com sucesso mas o
// Flutter não encontra o ficheiro final.
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Tem de ficar aqui, ANTES do evaluationDependsOn(":app") mais abaixo —
    // caso contrário o Gradle já avaliou o projeto quando tentamos registar
    // este afterEvaluate, e rebenta com "project is already evaluated".
    afterEvaluate {
        if (name == "flutter_local_notifications") {
            extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)?.apply {
                namespace = "com.dexterous.flutterlocalnotifications"
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}