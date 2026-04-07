package com.example.helloworldapp

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.rule.ActivityTestRule
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.matcher.ViewMatchers.*
import androidx.test.espresso.assertion.ViewAssertions.matches

@RunWith(AndroidJUnit4::class)
class HelloWorldTest {

    @get:Rule
    val activityRule = ActivityTestRule(MainActivity::class.java)

    @Test
    fun testHelloWorldTextDisplayed() {
        onView(withId(R.id.helloText))
            .check(matches(isDisplayed()))

        onView(withId(R.id.helloText))
            .check(matches(withText("Hello, World!")))
    }
}