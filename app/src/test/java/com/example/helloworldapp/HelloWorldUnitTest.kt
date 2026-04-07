package com.example.helloworldapp

import org.junit.Test
import org.junit.Assert.*

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
}