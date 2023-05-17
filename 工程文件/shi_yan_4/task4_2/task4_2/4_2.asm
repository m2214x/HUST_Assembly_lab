;1、用户名及密码定义时进行了加密
;2、登录模块使用了 穿插数据定义 以及使用了"自我修改返回地址"的子程序
;3、SF计算函数使用了动态修改执行代码,并且修改了SF的计算公式
;4、SF计算函数的进一步加密函数中穿插了无效代码
;5、使用了间接调用子程序
.686P 
.model flat, stdcall
  ExitProcess proto stdcall :dword
  includelib  kernel32.lib
  printf      proto c :vararg
  scanf      proto c :vararg
  VirtualProtect proto:dword, :dword, :dword, :dword
  putchar proto c:byte
  includelib  libcmt.lib
  includelib  legacy_stdio_definitions.lib

strcmp MACRO str1,str2;字符串比较宏指令
	local L1, outer, right, checkagain
	mov ecx,0
L1:
	mov al, str1[ecx]
	mov bl, str2[ecx]
	cmp bl,0 ;注意一下这里
	je checkagain
	xor bl, 'W' 
	cmp al,bl
	jnz outer
	inc ecx
	jmp L1
checkagain:
	cmp al, 0
	je right
outer:
	mov signflag, 0
	jmp sign_error
right:
endm

.data
;username db 'mengxiangwenxin',0
;password db 'kazuha1029',0
username db 'm' xor 'W', 'e' xor 'W','n' xor 'W','g' xor 'W','x' xor 'W','i' xor 'W','a' xor 'W','n' xor 'W','g' xor 'W','w' xor 'W','e' xor 'W','n' xor 'W','x' xor 'W','i' xor 'W','n' xor 'W',0
password db 'k' xor 'W', 'a' xor 'W','z' xor 'W','u' xor 'W','h' xor 'W','a' xor 'W','1' xor 'W','0' xor 'W','2' xor 'W', '9' xor 'W', 0 
tip1 db 'Welcome to this lab! Please input the username and your password(Enter to trans):',0
welcomestc db 'YES! Let''s start our travel!',0
retry db 'Wrong information! Please input again!',0
restart db 'Now all done. Click R to restart, or click Q to quit',0
wrong_to_quit db 'You have tried three times but all were wrong, now quit.',0
wrong_of_click db 'Input error! Please try again:',0

format1 db "%s",0;输入用户名及密码字符串
format2 db "%c",0
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
SAMID  db 9 DUP(0)	;每组数据的流水号
SDA   dd  ?			;状态信息a
SDB   dd  ?			;状态信息b
SDC   dd  ?			;状态信息c
SF    dd  ?			;处理结果f
samples ENDS

demo    SAMPLES <'00000001', 3200, 0, 0, >		    ;mid
	    SAMPLES <'00000002', 2333, 1136, 1, >		;
		SAMPLES <'00000003', 3100, 112, 6, >		;mid
		SAMPLES <'00000004', 3012, 196, 4, >		;mid
		SAMPLES <'00000005', 2333, 1451, 316, >		;
LOWF SAMPLES 50 dup(<>)
MIDF SAMPLES 50 dup(<>)
HIGHF SAMPLES 50 dup(<>)

samplecount dd ?
lowcnt dd ?
midcnt dd ?
highcnt dd ?

restarttip db 100 dup(0)

;用于动态修改执行代码的变量
machine_code db 0E8H, 05H,0, 0, 0;注意此处的
machine_len = $ - machine_code
oldprotect dd ?

;修改
Sampletype dd ?  
Choice dd ?
Result dd ?
TempNum dd ?
EsiBackUp dd ?
Table dd MySignIn, MySave, printMID, MyLreStart
num dd 0, 4, 8, 12


.stack 200
.code

;子程序1 配合MySignIN函数实现穿插数据定义，实现自我修改返回地址
Display proc
	pop ebx
PrintLoop:
	cmp byte ptr [ebx], 0
	je PrintExit
	invoke putchar, byte ptr [ebx]
	inc ebx
	jmp PrintLoop
PrintExit:
	inc ebx
	push ebx
	ret
Display endp

;子程序2 登录函数
MySignIn proc c
	mov Sampletype, type SAMPLES
	;登录模块
	mov signcount,3
SignIn:
	;invoke printf, offset lpFmt, offset tip1 ;改为穿插数据定义
	call Display
	msg1 db 'Welcome to this lab! Please input the username and your password(Enter to trans):',0ah, 0dh, 0
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
	;invoke printf, offset lpFmt, offset retry ;改为穿插数据定义
	call Display
	msg2 db 'Wrong information! Please input again!',0ah, 0dh, 0
	jmp SignIn
sign_done:
	;invoke printf, offset lpFmt, offset welcomestc ;改为穿插数据定义
	call Display
	msg3 db 'YES! Let''s start our travel!',0ah, 0dh, 0
	ret
sign_false:
	;invoke printf, offset lpFmt, offset wrong_to_quit ;改为穿插数据定义
	call Display
	msg4 db 'You have tried three times but all were wrong, now quit.',0ah, 0dh, 0
	invoke ExitProcess, 0
	ret
MySignIn endp

;子程序3 计算SF函数 动态修改执行代码
calculate proc, AA:dword, BB:dword, CC:dword  ;SF的计算公式为 SF = (SDA + SDB - 2 * SDC) >> 5
	mov eax, AA
    mov edx, BB
    add eax, edx
    mov edx, CC
	mov Result, eax
	mov TempNum, edx
	pushad;保护寄存器
	;call encipher ;讲这条语句改为动态修改
	mov eax, machine_len
    mov ebx, 40H
    lea ecx, CopyHere
    invoke VirtualProtect, ecx, eax, ebx, offset oldprotect
    mov ecx, machine_len
    mov edi, offset CopyHere
    mov esi, offset machine_code
 CopyCode:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    loop CopyCode
 CopyHere:
    db machine_len dup(0)
	popad;恢复寄存器
    ret
calculate endp

;子程序4 对SF计算进行跟进一步的加密 并且穿插一些无效代码
encipher proc
	mov eax, Result
	mov edx, TempNum
	imul edx, 2
	mov ecx, 100;无效代码1
	sub eax, edx
	sub ebx, edx;无效代码2
	sar eax, 5
	mov ecx, eax;无效代码3
	mov Result, eax
	ret
encipher endp

;子程序5 存储模块
MySave proc c
	mov eax, Result
	mov esi, EsiBackUp
	cmp eax, 100
	jg HIGHN
	jl LOWN
	je MIDN

LOWN:
	mov edi,lowcnt
    mov LOWF[edi].SF, eax
    mov eax, demo[esi].SDA
    mov LOWF[edi].SDA, eax
    mov eax,demo[esi].SDB
    mov LOWF[edi].SDB, eax
    mov eax,demo[esi].SDC
    mov LOWF[edi].SDC, eax
    mov ecx,0
LLow:
    mov ebx,dword ptr demo[esi].SAMID[ecx]
    mov dword ptr LOWF[edi].SAMID[ecx],ebx
    add ecx,4
    cmp ecx,8
    jl LLow
		add edi, Sampletype
		mov lowcnt,edi
        jmp SaveExit

MIDN:
	mov edi, midcnt
    mov MIDF[edi].SF, eax
    mov eax, demo[esi].SDA
    mov MIDF[edi].SDA, eax
    mov eax, demo[esi].SDB
    mov MIDF[edi].SDB, eax
    mov eax, demo[esi].SDC
    mov MIDF[edi].SDC, eax
    mov ecx,0
MMid:
    mov ebx,dword ptr demo[esi].SAMID[ecx]
    mov dword ptr MIDF[edi].SAMID[ecx],ebx
    add ecx,4
    cmp ecx,8
    jl MMid
		add edi, Sampletype
		mov midcnt, edi
        jmp SaveExit

HIGHN:
	mov edi,highcnt
    mov HIGHF[edi].SF,eax
    mov eax, demo[esi].SDA
    mov HIGHF[edi].SDA, eax
    mov eax, demo[esi].SDB
    mov HIGHF[edi].SDA, eax
    mov eax, demo[esi].SDC
    mov HIGHF[edi].SDA, eax
    mov ecx,0
HHigh:
    mov ebx,dword ptr demo[esi].SAMID[ecx]
    mov dword ptr LOWF[edi].SAMID[ecx],ebx
    add ecx,4
    cmp ecx,8
    jl HHigh
		add edi, Sampletype
		mov highcnt, edi
        jmp SaveExit

SaveExit:
	ret	
MySave endp

;子程序6 打印MIDF
printMID proc
    mov ebx,0
L1:
	mov edi, offset MIDF
	add edi, ebx
	invoke printf, offset samidprint, edi
    invoke printf, offset sdaprint, MIDF[ebx].SDA
    invoke printf, offset sdbprint, MIDF[ebx].SDB
    invoke printf, offset sdcprint, MIDF[ebx].SDC
    invoke printf, offset sfprint, MIDF[ebx].SF
    add ebx,Sampletype
    cmp ebx,midcnt
    jne L1
ret
printMID endp

;子程序7 按键等待状态函数
MyLreStart proc
	invoke printf, offset lpFmt, offset restart
Linput:
	invoke scanf, offset format1, offset restarttip
	mov al, restarttip ;读取第一个字符
	cmp al, 'r'
	je Exit1
	cmp al, 'q'
	je Exit2
	jne Lwrong
Lwrong:
	invoke printf, offset lpFmt, offset wrong_of_click
	jmp Linput
Exit1:
	mov Choice, 1
	ret
Exit2:
	mov Choice, 0
	ret
MyLreStart endp

;主程序
main proc c
;登录模块
	call Table[0] ;间接调用 
	;call MySignIn
;计算并存储流水线模块
MyLoop:
	mov lowcnt,0;LOW
	mov midcnt,0;MID
	mov highcnt,0;HIGH
	mov samplecount, 0
Lp:
	;计算模块
	mov esi, samplecount ;使用了esi 注意
	imul esi,Sampletype
	mov EsiBackUp, esi
	invoke calculate, demo[esi].SDA, demo[esi].SDB, demo[esi].SDC
	mov esi, EsiBackUp
	mov eax, Result
	mov demo[esi].SF, eax
	;存储模块
	mov ebx, num + 4
	call Table[ebx];间接调用
	;call MySave
	;循环控制
	inc samplecount
	cmp samplecount, 5
	jne Lp
;打印模块
	lea eax, Table + 8
	call dword ptr [eax];间接调用
	;call printMID 
;按键等待模块
	call Table[12];间接调用
	;call MyLreStart
	cmp Choice, 0
	je Exit
	jmp MyLoop
;程序退出模块
Exit:
	invoke ExitProcess, 0
main endp
end

