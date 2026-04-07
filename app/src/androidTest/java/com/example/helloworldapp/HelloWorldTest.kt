package com.example.helloworldapp

import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Test
import org.junit.runner.RunWith

import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.matcher.ViewMatchers.*
import androidx.test.espresso.assertion.ViewAssertions.matches

@RunWith(AndroidJUnit4::class)
class HelloWorldTest {

    @Test
    fun testHelloWorldTextDisplayed() {
        ActivityScenario.launch(MainActivity::class.java).use { scenario ->
            onView(withId(R.id.helloText))
                .check(matches(isDisplayed()))

            onView(withId(R.id.helloText))
                .check(matches(withText("Hello, World!")))
        }
    }
}