.686P 
.model flat, c
  ExitProcess proto stdcall :dword
  includelib  kernel32.lib
  printf      proto c :vararg
  scanf      proto c :vararg
  includelib  libcmt.lib
  includelib  legacy_stdio_definitions.lib
  calculate proto
  printMID proto :dword
  copy proto

strcmp MACRO str1,str2
;字符串比较宏指令
	local L1, outer, right
	mov ecx,0
L1:
	mov al, str1[ecx]
	mov bl, str2[ecx]
	cmp al,bl
	jnz outer
	inc ecx
	cmp al,0
	je right
	jmp L1
outer:
	mov signflag, 0
	jmp sign_error
right:
endm

.data
username db 'm',0
password db 'k',0
tip1 db 'Welcome to this lab! Please input the username and your password(Enter to trans):',0
welcomestc db 'YES! Let''s start our travel!',0
retry db 'Wrong information! Please input again!',0
restart db 'Now all done. Click r to restart, or click q to quit',0
wrong_to_quit db 'You have tried three times but all were wrong, now quit.',0
wrong_of_click db 'Input error! Please try again:',0

format1 db "%s",0;输入用户名及密码字符串
lpFmt db "%s",0ah,0dh,0
sdaprint db 'SDA:%d', 0ah, 0dh, 0
sdbprint db 'SDB:%d', 0ah, 0dh, 0
sdcprint db 'SDC:%d', 0ah, 0dh, 0
sfprint db 'SF:%d', 0ah, 0dh, 0ah, 0dh, 0
samidprint db 'SAMID:%s', 0ah, 0dh, 0

inputname db 20 dup(0)
inputpass db 20 dup(0)

signcount dd ?;登录尝试次数
signflag dd ?;登录是否成功，成功为1，失败为0

samples STRUCT
SAMID  db 8 DUP(0)	;每组数据的流水号
SDA   dd  ?			;状态信息a
SDB   dd  ?			;状态信息b
SDC   dd  ?			;状态信息c
SF    dd  ?			;处理结果f
samples ENDS

demo    SAMPLES <'00000001', 2333, 1, 1000, >		;low
	    SAMPLES <'00000002', 2333, 1136, 1, >		;mid
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
printMID proc xx:dword
;打印MIDF模块
	local yy:dword
	mov ebx,xx
	mov yy,ebx
    mov ebx,0
L1:
	mov edi, offset MIDF
	add edi, ebx
	invoke printf, offset samidprint, edi
    invoke printf, offset sdaprint, MIDF[ebx].SDA
    invoke printf, offset sdbprint, MIDF[ebx].SDB
    invoke printf, offset sdcprint, MIDF[ebx].SDC
    invoke printf, offset sfprint, MIDF[ebx].SF
    add ebx,yy
    cmp ebx,midcnt
    jne L1
ret
printMID endp


copy proc c
;存储运算结果至对应位置模块
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
		lea edi, sampletype
		mov lowcnt,edi
	ret

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
	ret

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
	ret
copy endp

main proc c
;登录模块
	mov signcount,3
SignIn:
	invoke printf, offset lpFmt, offset tip1
	invoke scanf, offset format1, offset inputname
	invoke scanf, offset format1, offset inputpass
	mov signflag, 1
	strcmp inputname, username
	strcmp inputpass, password
	cmp signflag, 1
	je sign_done
sign_error:
	dec signcount
	cmp signcount,0
	je sign_false
	invoke printf, offset lpFmt, offset retry
	jmp SignIn
sign_done:
	invoke printf, offset lpFmt, offset welcomestc
	jmp L0
sign_false:
	invoke printf, offset lpFmt, offset wrong_to_quit
	invoke ExitProcess, 0
	
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
	call calculate
	add esp, 12
	mov demo[ecx].SF, eax

	invoke copy

    inc samplecount
	cmp samplecount, 5
    jl Lpcal
	je result

result:
	invoke printMID, sampletype

Lrestart:
	invoke printf, offset lpFmt, offset restart
	invoke scanf, offset format1, offset restarttip
	cmp restarttip, 'r'
	je L0
	cmp restarttip, 'q'
	je Exit
	jne Lwrong
Lwrong:
	invoke printf, offset lpFmt, offset wrong_of_click
	jmp Lrestart
Exit:
	invoke ExitProcess, 0
	ret
main endp
end