.macro montgomery a,q,t,qinv
mul \t,\a,\qinv
ubfx \t,\t,#0,#18
mla \t,\t,\q,\a
lsr \a,\t,#18
.endm

.macro barrett a,q,t,c
add \t,\a,\a, LSL#2
smlatt \a,\c,\t,\a 	
.endm
.macro butterfly a0,a1,q,t,c
smlabb \t,\q,\c,\a0
sub \t,\t,\a1
add \a0,\a1
.endm

.macro butterfly_without_barrett a0,a1,w,q,t,c,qinv
butterfly \a0,\a1,\q,\t,\c
mul \a1,\t,\w
montgomery \a1,\q,\t,\qinv
.endm

.macro butterfly_with_barrett a0,a1,w,q,t,c,qinv
butterfly \a0,\a1,\q,\t,\c
barrett \a0,\q,\a1,\c
mul \a1,\t,\w
montgomery \a1,\q,\t,\qinv
.endm

.global	ntt
.type	ntt, %function
.align 4
.syntax unified
.cpu cortex-m4
/**
 * r0  		: poly pointer
 * r1  		: twiddle pointer
 * r2  		: loop counter 
 * r3 - r6 	: poly coeffs
 * r7  		: butterfly constant 3, barrett constant -q=53247 packed into one reg
 * r8  		: montgomery constant qinv=12287
 * r9  		: tmp var
 * r11 		: twiddle factor
 * r12		: tmp var
 * r14		: q=12289
 **/
ntt:
push {r4-r12,lr}
// q=12289
mov r14,#3
lsl r14,#12
add r14,#1

// qinv constant for montgomery reduction
sub r8, r14, #2

// constant 3 for butterfly and barrett reduction packed into one register
mov  r7, #3
movt r7, #53247

// init loop counter 
mov r2,#256
mov r9,r1

push {r0,r1}
level1to2:
// load 4 elements of a
ldrh r3,[r0],#2
ldrh r4,[r0],#2
ldrh r5,[r0],#2
ldrh r6,[r0],#2

// level 1
ldrh r11,[r1]
butterfly_without_barrett r3,r4,r11,r14,r12,r7,r8
ldrh r11,[r1,#2]
butterfly_without_barrett r5,r6,r11,r14,r12,r7,r8

// level 2
ldrh r11,[r9]
butterfly_with_barrett r3,r5,r11,r14,r12,r7,r8
butterfly_with_barrett r4,r6,r11,r14,r12,r7,r8

// store 4 elements of a
strh r3,[r0,#-8]
strh r4,[r0,#-6]
strh r5,[r0,#-4]
strh r6,[r0,#-2]

add r1,#4
add r9,#2

sub r2,#1
cmp r2,#0
bne level1to2

pop {r0,r1}

// reinit loop counter
mov r10, r1
level3to4: // unrolled 
lsl r11,r2,#2
add r1,r11

// load 4 elements of a
ldrh r3,[r0]
ldrh r4,[r0,#8]
ldrh r5,[r0,#16]
ldrh r6,[r0,#24]

// level 3
ldrh r11,[r1]
butterfly_without_barrett r3,r4,r11,r14,r12,r7,r8
ldrh r11,[r1,#2]
butterfly_without_barrett r5,r6,r11,r14,r12,r7,r8

// level 4
// Optimisation: twiddle remains in r9 
ldrh r9,[r10] 
butterfly_with_barrett r3,r5,r9,r14,r12,r7,r8
butterfly_with_barrett r4,r6,r9,r14,r12,r7,r8


// store 4 elements of a

strh r4,[r0,#8]
strh r5,[r0,#16]
strh r6,[r0,#24]
strh r3,[r0],#2

// load 4 elements of a
ldrh r3,[r0]
ldrh r4,[r0,#8]
ldrh r5,[r0,#16]
ldrh r6,[r0,#24]

// level 3
ldrh r11,[r1]
butterfly_without_barrett r3,r4,r11,r14,r12,r7,r8
ldrh r11,[r1,#2]
butterfly_without_barrett r5,r6,r11,r14,r12,r7,r8

// level 4
butterfly_with_barrett r3,r5,r9,r14,r12,r7,r8
butterfly_with_barrett r4,r6,r9,r14,r12,r7,r8

// store 4 elements of a
strh r4,[r0,#8]
strh r5,[r0,#16]
strh r6,[r0,#24]
strh r3,[r0],#2


// load 4 elements of a
ldrh r3,[r0]
ldrh r4,[r0,#8]
ldrh r5,[r0,#16]
ldrh r6,[r0,#24]

// level 3
ldrh r11,[r1]
butterfly_without_barrett r3,r4,r11,r14,r12,r7,r8
ldrh r11,[r1,#2]
butterfly_without_barrett r5,r6,r11,r14,r12,r7,r8

// level 4 
butterfly_with_barrett r3,r5,r9,r14,r12,r7,r8
butterfly_with_barrett r4,r6,r9,r14,r12,r7,r8

// store 4 elements of a
strh r4,[r0,#8]
strh r5,[r0,#16]
strh r6,[r0,#24]
strh r3,[r0],#2

// load 4 elements of a
ldrh r3,[r0]
ldrh r4,[r0,#8]
ldrh r5,[r0,#16]
ldrh r6,[r0,#24]

// level 3
ldrh r11,[r1]
butterfly_without_barrett r3,r4,r11,r14,r12,r7,r8
ldrh r11,[r1,#2]
butterfly_without_barrett r5,r6,r11,r14,r12,r7,r8

// level 4 
butterfly_with_barrett r3,r5,r9,r14,r12,r7,r8
butterfly_with_barrett r4,r6,r9,r14,r12,r7,r8

// store 4 elements of a

strh r4,[r0,#8]
strh r5,[r0,#16]
strh r6,[r0,#24]
strh r3,[r0], #26

// change r1 back to original address of omegas
sub r1,r1,r2, LSL#2

add r10,#2

add r2,#1
cmp r2,#64
bne level3to4


// restore r0
sub r0, #2048


push {r0, r1}
// outer loop counter
mov r10, #0
level5to6: 

// inner loop counter
mov r2, #0 
sub r11, r1, r10
ldrh r9,[r11]  
level5to6inner: 
// load 4 elements of a
ldrh r3,[r0]
ldrh r4,[r0,#32]
ldrh r5,[r0,#64]
ldrh r6,[r0,#96]

// level 5
ldrh r11,[r1]
butterfly_without_barrett r3,r4,r11,r14,r12,r7,r8
ldrh r11,[r1,#2]
butterfly_without_barrett r5,r6,r11,r14,r12,r7,r8


// level 6
butterfly_with_barrett r3,r5,r9,r14,r12,r7,r8
butterfly_with_barrett r4,r6,r9,r14,r12,r7,r8


// store 4 elements of a

strh r4,[r0,#32]
strh r5,[r0,#64]
strh r6,[r0,#96]
strh r3,[r0],#2

add r2, #2
cmp r2, #32
bne level5to6inner

add r1, #4
add r0, #96
add r10, #2
cmp r10, #32
bne level5to6

pop {r0,r1}      
push {r0,r1}
// set the loop counter to zero (zero because I am using it in address calculation of omegas)
mov r2,#0

// 7., 8, 9. layers merged and unrolled to merge with 10. layer
// first half calculate 7., 8., 9. layers with a[0:512]
// And it uses no multiplication for omegas[0]=1
firsthalf:
ldrh r3,[r0]
ldrh r4,[r0,#128]
ldrh r5,[r0,#256]
ldrh r6,[r0,#384]
ldrh r7,[r0,#512]
ldrh r8,[r0,#640]
ldrh r9,[r0,#768]
ldrh r10,[r0,#896]

// optimisation: using registers to store butterfly, barrett, and montgomery constants
push {r0,r2}
sub r0, r14, #2
mov  r2, #3
movt r2, #53247


// seventh layer
butterfly r3,r4,r14,r12,r2
mov r4,r12
//
ldrh r11,[r1,#2]
butterfly_without_barrett r5,r6,r11,r14,r12,r2,r0
// 
ldrh r11,[r1,#4]
butterfly_without_barrett r7,r8,r11,r14,r12,r2,r0
//
ldrh r11,[r1,#6]
butterfly_without_barrett r9,r10,r11,r14,r12,r2,r0

// eighth layer
//
butterfly r3,r5,r14,r12,r2
barrett r3,r14,r5,r2
barrett r12,r14,r5,r2
butterfly r4,r6,r14,r5,r2
barrett r4,r14,r6,r2
barrett r5,r14,r6,r2
// 
ldrh r11,[r1,#2]
butterfly_with_barrett r7,r9,r11,r14,r6,r2,r0
butterfly_with_barrett r8,r10,r11,r14,r6,r2,r0

// nineth layer
//
butterfly r3,r7,r14,r6,r2
butterfly r4,r8,r14,r7,r2
butterfly r12,r9,r14,r8,r2
butterfly r5,r10,r14,r9,r2

pop {r0,r2}

strh r9,[r0,#896]
strh r8,[r0,#768]
strh r7,[r0,#640]
strh r6,[r0,#512]
strh r5,[r0,#384]
strh r12,[r0,#256]
strh r4,[r0,#128]
strh r3,[r0],#2
add r2,#2
cmp r2,#128
bne firsthalf

pop {r0,r1}
add r0,#1024
mov r2,#0

// second half of 7., 8. and 9. layers 
// it calculates second half of output of 9. layer
// And load first half value and calculate 10. layer
// again no need to multiply with omegas[0]=1
lasthalf:
ldrh r3,[r0]
ldrh r4,[r0,#128]
ldrh r5,[r0,#256]
ldrh r6,[r0,#384]
ldrh r7,[r0,#512]
ldrh r8,[r0,#640]
ldrh r9,[r0,#768]
ldrh r10,[r0,#896]

push {r0,r2}
sub r0, r14, #2
mov  r2, #3
movt r2, #53247

// seventh layer
ldrh r11,[r1,#8]
butterfly_without_barrett r3,r4,r11,r14,r12,r2,r0
//
ldrh r11,[r1,#10]
butterfly_without_barrett r5,r6,r11,r14,r12,r2,r0
// 
ldrh r11,[r1,#12]
butterfly_without_barrett r7,r8,r11,r14,r12,r2,r0
//
ldrh r11,[r1,#14]
butterfly_without_barrett r9,r10,r11,r14,r12,r2,r0
//
// eighth layer
ldrh r11,[r1,#4]
butterfly_with_barrett r3,r5,r11,r14,r12,r2,r0
butterfly_with_barrett r4,r6,r11,r14,r12,r2,r0
// 
ldrh r11,[r1,#6]
butterfly_with_barrett r7,r9,r11,r14,r12,r2,r0
butterfly_with_barrett r8,r10,r11,r14,r12,r2,r0
//
// nineth layer
ldrh r11,[r1,#2]
// 
butterfly_without_barrett r3,r7,r11,r14,r12,r2,r0
butterfly_without_barrett r4,r8,r11,r14,r12,r2,r0
butterfly_without_barrett r5,r9,r11,r14,r12,r2,r0
butterfly_without_barrett r6,r10,r11,r14,r12,r2,r0

pop {r0, r2}
sub r0,#1024
// address of omegas won't be used after this point
// so we can use r1 as a 3q 
push {r1,r2}
// optimisation: using registers to store butterfly, barrett, and montgomery constants
push {r3}
movt r3, #53247

add r1,r14,r14,LSL#1

ldrh r11,[r0,#896]
ldrh r2,[r0,#768]

add r12,r11,r1
sub r12,r12,r10
add r10,r11
barrett r10,r14,r11,r3
barrett r12,r14,r11,r3

add r11,r2,r1
sub r11,r11,r9
add r9,r2
barrett r9,r14,r2,r3
barrett r11,r14,r2,r3

strh r9,[r0,#768]
strh r10,[r0,#896]
strh r11,[r0,#1792]
strh r12,[r0,#1920]
ldrh r11,[r0,#640]
ldrh r10,[r0,#512]
ldrh r9,[r0,#384]
ldrh r2,[r0,#256]

add r12,r11,r1
sub r12,r12,r8
add r8,r11
barrett r8,r14,r11,r3
barrett r12,r14,r11,r3

add r11,r10,r1
sub r11,r11,r7
add r7,r10
barrett r7,r14,r10,r3
barrett r11,r14,r10,r3

add r10,r9,r1
sub r10,r10,r6
add r6,r9
barrett r6,r14,r9,r3
barrett r10,r14,r9,r3

add r9,r2,r1
sub r9,r9,r5
add r5,r2
barrett r5,r14,r2,r3
barrett r9,r14,r2,r3

strh r8,[r0,#640]
strh r7,[r0,#512]
strh r6,[r0,#384]
strh r5,[r0,#256]
strh r12,[r0,#1664]
strh r11,[r0,#1536]
strh r10,[r0,#1408]
strh r9,[r0,#1280]
ldrh r11,[r0,#128]
ldrh r10,[r0]


// r12,r4
add r12,r11,r1
sub r12,r12,r4
add r4,r11
barrett r12,r14,r11,r3
barrett r4,r14,r11,r3

mov r2, r3
pop {r3}

// r11,r3
add r11,r10,r1
sub r11,r11,r3
add r3,r10
barrett r11,r14,r10,r2
barrett r3,r14,r10,r2

strh r4,[r0,#128]
strh r12,[r0,#1152]
strh r11,[r0,#1024]
strh r3,[r0],#2

pop {r1,r2}
add r0,#1024
add r2,#2
cmp r2,#128
bne lasthalf
pop {r4-r12,pc}

.global	mul_coefficients
.type	mul_coefficients, %function
// unaligned loads and store add one cycle each block
.align 4
.syntax unified
.cpu cortex-m4

mul_coefficients:
push {r4-r12,lr}

mov r2, #128
// set r14 as q
mov r14,#3
lsl r14,#12
add r14,#1
sub r12,r14,#2
mov r11,#0
looptop:

ldm r0,{r3,r4}
ldm r1!,{r7,r8}

smulbb r5,r3,r7
mul r9,r5,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r5
lsr r5,r9,#18
smultt r6,r3,r7
mul r9,r6,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r6
lsr r6,r9,#2
pkhbt r3, r5, r6

smulbb r5,r4,r8
mul r9,r5,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r5
lsr r5,r9,#18
smultt r6,r4,r8
mul r9,r6,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r6
lsr r6,r9,#2
pkhbt r4, r5, r6

ldrd r5,r6,[r0,#8]
ldm r1!,{r7,r8}

smulbb r10,r5,r7
mul r9,r10,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r10
lsr r10,r9,#18
smultt r7,r5,r7
mul r9,r7,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r7
lsr r7,r9,#2
pkhbt r5, r10, r7

smulbb r10,r6,r8
mul r9,r10,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r10
lsr r10,r9,#18
smultt r8,r6,r8
mul r9,r8,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r8
lsr r8,r9,#2
pkhbt r6, r10, r8

stm r0!,{r3,r4,r5,r6}

sub r2,#1
cmp r2,#0
bne looptop

pop {r4-r12,pc}	

.global bitrev_vector
.type bitrev_vector, %function
.align 2
.syntax unified
.cpu cortex-m4

bitrev_vector:
push {r0-r12,lr}
mov r1,#2
rbit r2,r1
lsr r2,#20
mov r5,#7 
lsl r5,#8
add r5,#190
looptopb:
ldrh r3,[r0,r1]
ldrh r4,[r0,r2]
strh r3,[r0,r2]
strh r4,[r0,r1]
cmp r1,r5
beq exit
loopin:
add r1,#2
rbit r2,r1
lsr r2,#20
cmp r2,r1
ble loopin
b looptopb
exit:
pop {r0-r12,pc}

.global	poly_pointwise
.type	poly_pointwise, %function
// unaligned loads and store add one cycle each block
.align 4
.syntax unified
.cpu cortex-m4

poly_pointwise:
push {r0-r12,lr}

mov r10, #128
// set r14 as q
mov r14,#3
lsl r14,#12
add r14,#1
sub r12,r14,#2
mov r11,#3072
add r11,#114
looptopp:
ldm r1!,{r3,r4}
ldm r2!,{r7,r8}
push {r10}

smulbb r5,r11,r7
mul r9,r5,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r5
lsr r5,r9,#18
smulbb r5,r5,r3
mul r9,r5,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r5
lsr r5,r9,#18
smulbt r6,r11,r7
mul r9,r6,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r6
lsr r6,r9,#18
smulbt r6,r6,r3
mul r9,r6,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r6
lsr r6,r9,#2
pkhbt r3, r5, r6

smulbb r5,r11,r8
mul r9,r5,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r5
lsr r5,r9,#18
smulbb r5,r5,r4
mul r9,r5,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r5
lsr r5,r9,#18
smulbt r6,r11,r8
mul r9,r6,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r6
lsr r6,r9,#18
smulbt r6,r6,r4
mul r9,r6,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r6
lsr r6,r9,#2
pkhbt r4, r5, r6

ldrd r5,r6,[r1],#8
ldm r2!,{r7,r8}

smulbb r10,r11,r7
mul r9,r10,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r10
lsr r10,r9,#18
smulbb r10,r10,r5
mul r9,r10,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r10
lsr r10,r9,#18
smulbt r7,r11,r7
mul r9,r7,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r7
lsr r7,r9,#18
smulbt r7,r7,r5
mul r9,r7,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r7
lsr r7,r9,#2
pkhbt r5, r10, r7

smulbb r10,r11,r8
mul r9,r10,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r10
lsr r10,r9,#18
smulbb r10,r10,r6
mul r9,r10,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r10
lsr r10,r9,#18
smulbt r8,r11,r8
mul r9,r8,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r8
lsr r8,r9,#18
smulbt r8,r8,r6
mul r9,r8,r12
ubfx r9,r9,#0,#18
mla r9,r9,r14,r8
lsr r8,r9,#2
pkhbt r6, r10, r8
pop {r10}
stm r0!,{r3,r4,r5,r6}

sub r10,#1
cmp r10,#0
bne looptopp

pop {r0-r12,pc}	



.macro sample_coeff r, bufv, q, const, tmp1, tmp2, tmp3, tmp4

  and \tmp2, \const, \bufv
  v = 1
  .rept 7
    and \tmp3, \const, \bufv, LSR#v
    add \tmp2, \tmp3
    v=v+1
  .endr
  // tmp2 = (\tmp1>>k) & 0x01010101 

  // a + Q - b
  ubfx \tmp1, \tmp2, #0, #8
  ubfx \tmp3, \tmp2, #8, #8 
  add \tmp1, \q 
  sub \tmp1, \tmp3 
  strh \tmp1, [\r], #2

  // c + Q - d
  ubfx \tmp1, \tmp2, #16, #8
  add \tmp1, \q
  sub \tmp1, \tmp1, \tmp2, LSR#24
  
  strh \tmp1, [\r], #2
.endm

//poly_sample_inner2(buf, r, extseed);
.global	poly_sample_inner
.type	poly_sample_inner, %function
.align 4
.syntax unified
.cpu cortex-m4
poly_sample_inner: 
  push {r4-r12,lr}
  // write arguments for shake on the stack 
  sub	sp, #16
  movs	r4, #34
  movs	r5, #0
  strd	r4, r5, [sp, #8]
  str	  r2, [sp]

  // save the arguments 
  // buf 
  mov r4, r0 
  // poly 
  mov r5, r1
  // seed 
  mov r6, r2 

  // q=12289
  mov r10,#3
  lsl r10,#12
  add r10,#1

  mov  r11, #0x01010101

  // i
  movs	r7, #0
  
  poly_sample_outer_loop: 
    // extseed[NEWHOPE_SYMBYTES+1] = i;
    strb r7, [r6, #33]

    // shake256(buf,128,extseed,NEWHOPE_SYMBYTES+2);
    movs	r2, #128	
 	  movs	r3, #0
 	  mov	r0, r4
 	  bl shake256
    
    // j 
    mov r8, #8
    poly_sample_inner_loop:
    
      ldr r0, [r4], #4
      ldr r1, [r4], #4
      ldr r2, [r4], #4
      ldr r3, [r4], #4
  
      sample_coeff r5, r0, r10, r11, r9, r12, r14
      sample_coeff r5, r1, r10, r11, r9, r12, r14
      sample_coeff r5, r2, r10, r11, r9, r12, r14
      sample_coeff r5, r3, r10, r11, r9, r12, r14
      subs r8, #1 // j
      bne poly_sample_inner_loop
    sub r4, #128 // reset buf 

    add r7, #1 //i
    cmp r7, #16
    bne poly_sample_outer_loop
  add sp, #16
  pop {r4-r12, pc}