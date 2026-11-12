package app.totp.core

import org.junit.Assert.assertEquals
import org.junit.Test

class Base32Test {
    @Test
    fun ignoresSpaces() {
        val decoded = decodeBase32("GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ")
        assertEquals("12345678901234567890", decoded.toString(Charsets.US_ASCII))
    }

    @Test
    fun rejectsInvalidInput() {
        fails { decodeBase32("") }
        fails { decodeBase32("   ") }
        fails { decodeBase32("GEZD1") }
        fails { decodeBase32("GEZD==") }
    }

    @Test
    fun roundTrips() {
        val decoded = decodeBase32("GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ")
        assertEquals(decoded.toList(), decodeBase32(encodeBase32(decoded)).toList())
    }
}
