.686P 
.model flat, c
  ExitProcess proto stdcall :dword
  includelib  kernel32.lib
  printf      proto c :vararg
  scanf      proto c :vararg
  includelib  libcmt.lib
  includelib  legacy_stdio_definitions.lib
  calculate proto
  printMID proto :dword, :dword
  check proto c:dword, :dword, :dword
  ifrestart proto :dword, :dword

.data
username db 'm',0
password db 'k',0

format1 db "%s",0;输入用户名及密码字符串
lpFmt db "%s",0ah,0dh,0
sdaprint db 'SDA:%d', 0ah, 0dh, 0
sdbprint db 'SDB:%d', 0ah, 0dh, 0
sdcprint db 'SDC:%d', 0ah, 0dh, 0
sfprint db 'SF:%d', 0ah, 0dh, 0ah, 0dh, 0
samidprint db 'SAMID:%s', 0ah, 0dh, 0

inputname db 20 dup(0)
inputpass db 20 dup(0)

signflag dd ?;登录是否成功，成功为1，失败为0

samples STRUCT
SAMID  db 8 DUP(0)	;每组数据的流水号
SDA   dd  ?			;状态信息a
SDB   dd  ?			;状态信息b
SDC   dd  ?			;状态信息c
SF    dd  ?			;处理结果f
samples ENDS

demo	SAMPLES <'00000001', 2333, 1136, 1, >		;mid
        SAMPLES <'00000002', 2333, 1, 1000, >		;low
		SAMPLES <'00000003', 2333, 2000, 1, >		;high
		SAMPLES <'00000004', 2333, 2000, 865, >		;mid
		SAMPLES <'00000005', 2333, 1451, 316, >		;mid
LOWF SAMPLES 5 dup(<>)
MIDF SAMPLES 5 dup(<>)
HIGHF SAMPLES 5 dup(<>)

samplecount dd ?
lowcnt dd ?
midcnt dd ?
highcnt dd ?
sampletype dd type SAMPLES
restarttip db ?


.code

main proc c
;登录模块
SignIn:
	invoke check, offset username, offset password, offset signflag
	cmp signflag,1
	jne Exit
	
;计算流水线模块
L0:
	mov lowcnt,0;LOW
	mov midcnt,0;MID
	mov highcnt,0;HIGH
	mov samplecount, 0
Lpcal:
	mov ecx, samplecount
	imul ecx,sampletype
	push demo[ecx].SDC
	push demo[ecx].SDB
	push demo[ecx].SDA
	;invoke calculate, demo[ecx].SDA, demo[ecx].SDB, demo[ecx].SDC
	call calculate
	add esp, 12
	mov demo[ecx].SF, eax
	cmp eax, 100
	jg HIGHN
	jl LOWN
	je MIDN

LOWN:
	mov edi,lowcnt
    mov LOWF[edi].SF, eax
    mov eax, demo[ecx].SDA
    mov LOWF[edi].SDA, eax
    mov eax,demo[ecx].SDB
    mov LOWF[edi].SDB, eax
    mov eax,demo[ecx].SDC
    mov LOWF[edi].SDC, eax
    mov ebp,0
LLow:
    mov ebx,dword ptr demo[ecx].SAMID[ebp]
    mov dword ptr LOWF[edi].SAMID[ebp],ebx
    INC ebp
    cmp ebp,2
    jl LLow
		add edi, sampletype
        inc samplecount
	    cmp samplecount, 5
        jl Lpcal
		je result

MIDN:
	mov edi, midcnt
    mov MIDF[edi].SF, eax
    mov eax, demo[ecx].SDA
    mov MIDF[edi].SDA, eax
    mov eax, demo[ecx].SDB
    mov MIDF[edi].SDB, eax
    mov eax, demo[ecx].SDC
    mov MIDF[edi].SDC, eax
    mov ebp,0
MMid:
    mov ebx,dword ptr demo[ecx].SAMID[ebp]
    mov dword ptr MIDF[edi].SAMID[ebp],ebx
    add ebp,4
    cmp ebp,8
    jl MMid
		add edi, sampletype
		mov midcnt, edi
        inc samplecount
	    cmp samplecount, 5
        jl Lpcal
		je result

HIGHN:
	mov edi,highcnt
    mov HIGHF[edi].SF,eax
    mov eax, demo[ecx].SDA
    mov HIGHF[edi].SDA, eax
    mov eax, demo[ecx].SDB
    mov HIGHF[edi].SDA, eax
    mov eax, demo[ecx].SDC
    mov HIGHF[edi].SDA, eax
    mov ebp,0
HHigh:
    mov ebx,dword ptr demo[ecx].SAMID[ebp]
    mov dword ptr LOWF[edi].SAMID[ebp],ebx
    INC ebp
    cmp ebp,2
    jl HHigh
		add edi, sampletype
		mov highcnt, edi
        inc samplecount
	    cmp samplecount, 5
        jl Lpcal
		je result

result:
	invoke printMID, offset MIDF, midcnt

Lrestart:
	invoke ifrestart,offset demo, offset restarttip
    cmp restarttip, 0
    jg L0
    jl Exit
Exit:
	invoke ExitProcess, 0
main endp
end
