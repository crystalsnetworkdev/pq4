.cpu cortex-m4
.syntax unified
.thumb

//void frodo_unpack(uint16_t *out, const size_t outlen, const unsigned char *in, const size_t inlen, const unsigned char lsb);
// =>
//void frodo_unpack(uint16_t *out, const unsigned char *in, const size_t inlen);
.align 2
.global frodo_unpack
.type frodo_unpack,%function
frodo_unpack:
//assume lsb == 15
//assume inlen = 1.875*outlen
//assume in and out are large enough
//then 15 unsigned chars need to go to 8 uint16_t (of which 15 bits are used)
//assume inlen is a multiple of 60
//out in r0, in in r1, inlen in r2
    push {r4-r10}

    mov r3, #0x7fff

unpack_loop:
    ldm r1!, {r4-r7}

    rev r4, r4
    rev r5, r5
    rev r6, r6
    rev r7, r7

    and r8, r3, r4, lsr #17
    and r9, r4, #0x3
    and r4, r3, r4, lsr #2
    orr r4, r4, r8, lsl #16

    and r8, r3, r5, lsr #19
    and r10, r5, #0xf
    and r5, r3, r5, lsr #4
    orr r5, r5, r8, lsl #16
    orr r5, r5, r9, lsl #29

    and r8, r3, r6, lsr #21
    and r9, r6, #0x3f
    and r6, r3, r6, lsr #6
    orr r6, r6, r8, lsl #16
    orr r6, r6, r10, lsl #27

    and r8, r3, r7, lsr #23
    and r10, r7, #0xff
    and r7, r3, r7, lsr #8
    orr r7, r7, r8, lsl #16
    orr r7, r7, r9, lsl #25

    rev r4, r4
    rev16 r4, r4
    rev r5, r5
    rev16 r5, r5
    rev r6, r6
    rev16 r6, r6
    rev r7, r7
    rev16 r7, r7

    stm r0!, {r4-r7}
    ldm r1!, {r4-r7}

    rev r4, r4
    rev r5, r5
    rev r6, r6
    rev r7, r7

    and r8, r3, r4, lsr #25
    and r9, r4, r3, lsr #5
    and r4, r3, r4, lsr #10
    orr r4, r4, r8, lsl #16
    orr r4, r4, r10, lsl #23

    and r8, r3, r5, lsr #27
    and r10, r5, r3, lsr #3
    and r5, r3, r5, lsr #12
    orr r5, r5, r8, lsl #16
    orr r5, r5, r9, lsl #21

    and r8, r3, r6, lsr #29
    and r9, r6, r3, lsr #1
    and r6, r3, r6, lsr #14
    orr r6, r6, r8, lsl #16
    orr r6, r6, r10, lsl #19

    and r8, r3, r7, lsr #31
    uxth r10, r7
    and r7, r3, r7, lsr #16
    orr r7, r7, r8, lsl #16
    orr r7, r7, r9, lsl #17

    rev r4, r4
    rev16 r4, r4
    rev r5, r5
    rev16 r5, r5
    rev r6, r6
    rev16 r6, r6
    rev r7, r7
    rev16 r7, r7

    stm r0!, {r4-r7}
    ldm r1!, {r4-r7}

    rev r4, r4
    rev r5, r5
    rev r6, r6
    rev r7, r7

    lsr r8, r10, #1
    and r10, #1
    lsl r8, #16
    orr r8, r8, r10, lsl #14

    and r9, r3, r4, lsr #18
    orr r8, r9

    and r9, r3, r4, lsr #3
    and r4, #0x7
    and r10, r3, r5, lsr #20
    orr r4, r10, r4, lsl #12
    orr r4, r4, r9, lsl #16

    and r9, r3, r5, lsr #5
    and r5, #0x1f
    and r10, r3, r6, lsr #22
    orr r5, r10, r5, lsl #10
    orr r5, r5, r9, lsl #16

    and r9, r3, r6, lsr #7
    and r6, #0x7f
    and r10, r3, r7, lsr #24
    orr r6, r10, r6, lsl #8
    orr r6, r6, r9, lsl #16

    rev r8, r8
    rev16 r8, r8
    rev r4, r4
    rev16 r4, r4
    rev r5, r5
    rev16 r5, r5
    rev r6, r6
    rev16 r6, r6

    str r8, [r0], #4
    str r4, [r0], #4
    str r5, [r0], #4
    str r6, [r0], #4
    ldr r8, [r1], #4
    ldr r4, [r1], #4
    ldr r5, [r1], #4

    rev r8, r8
    rev r4, r4
    rev r5, r5

    and r9, r3, r7, lsr #9
    and r10, r7, r3, lsr #6
    and r7, r3, r8, lsr #26
    orr r7, r7, r10, lsl #6
    orr r7, r7, r9, lsl #16

    and r9, r3, r8, lsr #11
    and r10, r8, r3, lsr #4
    and r8, r3, r4, lsr #28
    orr r8, r8, r10, lsl #4
    orr r8, r8, r9, lsl #16

    and r9, r3, r4, lsr #13
    and r10, r4, r3, lsr #2
    and r4, r3, r5, lsr #30
    orr r4, r4, r10, lsl #2
    orr r4, r4, r9, lsl #16

    and r9, r3, r5, lsr #15
    and r5, r3
    orr r5, r5, r9, lsl #16

    rev r7, r7
    rev16 r7, r7
    rev r8, r8
    rev16 r8, r8
    rev r4, r4
    rev16 r4, r4
    rev r5, r5
    rev16 r5, r5

    str r7, [r0], #4
    str r8, [r0], #4
    str r4, [r0], #4
    str r5, [r0], #4

    subs r2, #60
    bne unpack_loop

    pop {r4-r10}
    bx lr
