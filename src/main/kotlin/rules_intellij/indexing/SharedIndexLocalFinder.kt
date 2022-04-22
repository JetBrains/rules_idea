package rules_intellij.indexing

import com.intellij.openapi.project.Project
import java.nio.file.Path

interface SharedIndexLocalFinder {
  fun findSharedIndexChunks(project: Project): List<Path>
}