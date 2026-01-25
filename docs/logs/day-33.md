# Day 33 - 2026 January 26 10.10AM
Looking at arithmetic logic properly now. Maybe it'll be time to refactor the instructions again from the code review.

Here's one of the recommendation summarised 
A packed struct can be used to represent the encoding of the instruction so we could just bitcast the instructions to
it. It's nice as long as the encoding is not too complex and even then you can use methods for more complex
encodings. For the registers I used an std.EnumArray
