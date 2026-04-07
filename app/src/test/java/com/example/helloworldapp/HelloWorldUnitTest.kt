package com.example.helloworldapp

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import org.junit.Test
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment

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
        val context = RuntimeEnvironment.getApplication()
        assertNotNull(context)
        assertEquals("com.example.helloworldapp", context.packageName)
    }
}