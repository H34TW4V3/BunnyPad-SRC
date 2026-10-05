package org.bunnypad.android.ui.main

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import org.bunnypad.android.MainActivity
import org.junit.Rule
import org.junit.Test

/** End-to-end editor checks. Run on an emulator/device with connectedDebugAndroidTest. */
class MainScreenTest {
    @get:Rule val rule = createAndroidComposeRule<MainActivity>()

    @Test fun editUndoRedoAndUnsavedGuard() {
        rule.waitUntil(10_000) { rule.onAllNodesWithText("Menu").fetchSemanticsNodes().isNotEmpty() }
        rule.waitForIdle()
        rule.onNodeWithTag("noteEditor").performTextReplacement("Bunny note")
        rule.onNodeWithTag("noteEditor").assertTextEquals("Bunny note")
        rule.onNodeWithText("Undo").performClick()
        rule.onNodeWithText("Redo").performClick()
        rule.onNodeWithTag("noteEditor").assertTextEquals("Bunny note")
        rule.onNodeWithText("Menu").performClick()
        rule.onNodeWithText("New").performClick()
        rule.onNodeWithText("Save your changes?").assertIsDisplayed()
        rule.onNodeWithText("Cancel").performClick()
        rule.onNodeWithTag("noteEditor").assertTextEquals("Bunny note")
    }

    @Test fun noteSurvivesActivityRecreation() {
        rule.waitForIdle()
        rule.onNodeWithTag("noteEditor").performTextReplacement("Keep this draft")
        rule.activityRule.scenario.recreate()
        rule.onNodeWithTag("noteEditor").assertTextEquals("Keep this draft")
    }
}
