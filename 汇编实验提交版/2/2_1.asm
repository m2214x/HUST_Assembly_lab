.686P
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
__fmtTime	db	"Time consumed is %ld ms", 2 dup(0ah, 0dh), 0

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
    SAMID  DB 6 DUP(0)
    SDA   DD  256809
    SDB   DD - 1023
    SDC   DD   1265
    SF    DD   ?
samples ends

.data
    demo    SAMPLES  <'000001', 321, 432, 10, ? >
            SAMPLES  <'000002', 12654, 544, 342, ? >
            SAMPLES  <'000003', 32100654, 432, 10, ? >
            SAMPLES  10000-3 DUP(<>)       ;剩下的N-3组信息的初始值都相同并不影响实验效果。



    LOWF   SAMPLES 10000 dup(<>); 三个存放数据区
    MIDF   SAMPLES 10000 dup(<>)
    HIGHF  SAMPLES 10000 dup(<>)
divn DD 128


.stack   200
.code

main proc

invoke winTimer, 0

mov ecx, 10000
mov ebx,0;
mov esi,0;
mov edi,0;
mov edx,0; 遍历demo数组使用

LOOPA:
mov  esi,0
Lx:
mov eax, demo[edx].SDA
mov edx,0
;sal eax,2
;add eax, demo[edx].SDA
imul eax,5
add eax, demo[edx].SDB
sub eax, demo[edx].SDC
add eax, 100
;idiv divn
shr eax, 7
    inc esi
    cmp esi, 40000
    jl Lx
    mov edi,0
    mov demo[edx].SF,eax
    sub demo[edx].SF, 100
    cmp demo[edx].SF, 0
    jz MIDN
    js LOWN
    jns HIGHN



LOWN:
    mov LOWF[0].SF, eax
    mov eax, demo[edx].SDA
    mov LOWF[0].SDA, eax
    mov eax,demo[edx].SDB
    mov LOWF[0].SDB, eax
    mov eax,LOWF[edx].SDC
    mov LOWF[0].SDC, eax
    mov ebp,0
LLow:
    mov ebx, dword ptr demo[edx].SAMID[ebp]
    mov dword ptr LOWF[0].SAMID[ebp],ebx
    INC ebp
    cmp ebp,2
    jl LLow
            inc edi
            cmp edi,40000
            jl LOWN
        INC   edx
        DEC   ecx
        JNE   LOOPA
        jmp   Ex
MIDN:
    mov MIDF[0].SF, eax
    mov eax, demo[edx].SDA
    mov MIDF[0].SDA, eax
    mov eax, demo[edx].SDB
    mov MIDF[0].SDB, eax
    mov eax, demo[edx].SDC
    mov MIDF[0].SDC, eax
    mov ebp,0
MMid:
    mov ebx,  dword ptr demo[edx].SAMID[ebp]
    mov dword ptr MIDF[0].SAMID[ebp],ebx
    INC ebp
    cmp ebp,2
    jl MMid
            inc edi
            cmp edi,40000
            jl MIDN
        INC   edx
        DEC   ecx
        JNE   LOOPA
        jmp   Ex
HIGHN:
    mov HIGHF[0].SF,eax
    mov eax, demo[edx].SDA
    mov HIGHF[0].SDA, eax
    mov eax, demo[edx].SDB
    mov HIGHF[0].SDA, eax
    mov eax, demo[edx].SDC
    mov HIGHF[0].SDA, eax
    mov ebp,0
HHigh:
    mov ebx, dword ptr demo[edx].SAMID[ebp]
    mov dword ptr LOWF[0].SAMID[ebp],ebx
    INC ebp
    cmp ebp,2
    jl HHigh
            inc edi
            cmp edi,40000
            jl HIGHN
        INC   edx
        DEC   ecx
        JNE   LOOPA
        jmp   Ex




Ex:
    invoke winTimer, 1
    invoke ExitProcess, 0

main  endp
end

