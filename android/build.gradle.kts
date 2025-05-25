import com.android.build.gradle.LibraryExtension
import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 自定义构建目录（可选骚操作）
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 保证 app 项目优先评估
subprojects {
    project.evaluationDependsOn(":app")
}

// clean 任务定义
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ✅ 安全方式补 namespace（避免 afterEvaluate 报错）
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension> {
            if (namespace == null || namespace!!.isBlank()) {
                namespace = "com.example.${project.name.replace("-", "_")}"
            }
        }
    }
}
