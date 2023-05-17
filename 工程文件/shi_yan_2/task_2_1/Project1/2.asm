.686
.model flat, c
ExitProcess proto stdcall : dword
includelib  kernel32.lib
printf      proto c : vararg
scanf      proto c : vararg
includelib  libcmt.lib
includelib  legacy_stdio_definitions.lib


timeGetTime proto stdcall
includelib  Winmm.lib

.DATA
__t1		dd ?
__t2		dd ?
__fmtTime	db	0ah, 0dh, "Time consumed is %ld ms", 2 dup(0ah, 0dh), 0

.CODE
winTimer	proc stdcall, flag : DWORD
jmp	__L1
__L1 :
call timeGetTime
cmp	flag, 0
jnz	__L2
mov	__t1, eax
ret	4
__L2 :
    mov	__t2, eax
    sub	eax, __t1
    invoke	printf, offset __fmtTime, eax
    ret	4
    winTimer	endp


    samples struct
    SAMID  DB 9 DUP(0)
    SDA   DD  256809
    SDB   DD - 1023
    SDC   DD   1265
    SF    DD ?
    samples ends

    .data

    demo SAMPLES <'1', 321, 432, 10, ? >
    SAMPLES  <'2', 12654, 544, 342, ? >
    SAMPLES  <'3', 32100654, 432, 10, ? >
    SAMPLES  10000 - 3 dup(<>)


    LOWF   SAMPLES 10000 dup(<>); 三个存放数据区
    MIDF   SAMPLES 10000 dup(<>)
    HIGHF  SAMPLES 10000 dup(<>)
    divn DD 128


    .stack   200
    .code

    main proc

    invoke winTimer, 0

    mov ecx, 10000
    mov ebx, 0
    mov edx, 0

    LOOPA:

mov eax, demo[edx].SDA
imul eax, 5
add eax, demo[edx].SDB
sub eax, demo[edx].SDC
add eax, 100
; idiv divn
shr eax, 7



mov demo[edx].SF, eax
sub demo[edx].SF, 100
cmp demo[edx].SF, 0
jz MIDN
js LOWN
jns HIGHN



LOWN:
mov LOWF[ebx].SF, eax
mov eax, demo[ebx].SDA
mov LOWF[ebx].SDA, eax
mov eax, demo[ebx].SDB
mov LOWF[ebx].SDB, eax
mov eax, LOWF[ebx].SDC
mov LOWF[ebx].SDC, eax
INC ebx
INC   edx
DEC   ecx
JNE   LOOPA
MIDN :
mov MIDF[ebx].SF, eax
mov eax, demo[ebx].SDA
mov MIDF[ebx].SDA, eax
mov eax, demo[ebx].SDB
mov MIDF[ebx].SDB, eax
mov eax, demo[ebx].SDC
mov MIDF[ebx].SDC, eax
INC ebx
INC   edx
DEC   ecx
JNE   LOOPA
HIGHN :
mov HIGHF[ebx].SF, eax
mov eax, demo[ebx].SDA
mov HIGHF[ebx].SDA, eax
mov eax, demo[ebx].SDB
mov HIGHF[ebx].SDA, eax
mov eax, demo[ebx].SDC
mov HIGHF[ebx].SDA, eax
INC ebx
INC   edx
DEC   ecx
JNE   LOOPA




invoke winTimer, 1
invoke ExitProcess, 0

main  endp
end
