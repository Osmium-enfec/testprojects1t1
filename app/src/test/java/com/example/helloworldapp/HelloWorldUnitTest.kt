package com.example.helloworldapp

import androidx.test.core.app.ApplicationProvider
import org.junit.Test
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class HelloWorldUnitTest {
    
    @Test
    fun testHelloWorldString() {
        val expectedText = "Hello, World!"
        assertEquals("Hello, World!", expectedText)
    }
    
    @Test
    fun testStringNotEmpty() {
        val text = "Hello, World!"
        assertFalse(text.isEmpty())
    }
    
    @Test
    fun testStringLength() {
        val text = "Hello, World!"
        assertEquals(13, text.length)
    }
    
    @Test
    fun testApplicationContext() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        assertNotNull(context)
        assertEquals("com.example.helloworldapp", context.packageName)
    }
}