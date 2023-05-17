;第三代版本
;1、用户名和密码进行了加密
;2、用户名和密码的比较函数 里面 xor Mychar, 'M' 采用了动态修改执行代码的方式进行更强的加密，使得别人难以发现对字符串做了何种操作
;2、Calcoptimize子程序的调用改为了动态修改执行代码 并且修改了SF的计算公式
;3、设计了一个多余的calculate函数，用于干扰
;4、在上面两个calc函数中都穿插了一些无效代码 用于干扰
;5、按键等待状态子程序中穿插了数据定义
;6、间接调用Login函数

.686P
.model flat, stdcall
 ExitProcess proto stdcall:dword
 printf proto c:ptr sbyte, :vararg
 scanf proto c:ptr sbyte, :vararg
 putchar proto c:byte
 VirtualProtect proto:dword, :dword, :dword, :dword
 includelib kernel32.lib
 includelib libcmt.lib
 includelib legacy_stdio_definitions.lib
 timeGetTime proto stdcall
 includelib Winmm.lib

 ;结构体定义 
 SAMPLES STRUCT 
 	SAMID DB 6 DUP(0)
 	SDA DD ?
 	SDB DD ?
	SDC DD ?
	SF DD ?
 SAMPLES ENDS

.data ;数据段定义
 ;三个存储区
 LOWF SAMPLES 1000 DUP(<>)
 MIDF   SAMPLES 1000 DUP(<>)
 HIGHF  SAMPLES 1000 DUP(<>)
 ;存储区偏移
 LowBias dd 0
 MidBias dd 0
 HighBias dd 0
 ;结构体数组
 INPUT  SAMPLES <'1',1260, 100, 22, ?> ;mid
		SAMPLES <'2',1200, 478, 100, ?> ;mid
		SAMPLES <'3',10, 1, 1, ?> ;low
		SAMPLES <'4',20, 4, 1, ?> ;low
		SAMPLES <'5',1200000, 1, 1, ?> ;high
 ;结构体大小
 SizeOfSamples dd ?
 ;用户名与密码
 ;names db 'linguangming', 0 ;原先的用户名
 ;password db 'lgm381521', 0 ;原先的密码
 names db 'l' xor 'M', 'i' xor 'M', 'n' xor 'M', 'g' xor 'M',  'u' xor 'M',  'a' xor 'M',  'n' xor 'M',  'g' xor 'M',  'm' xor 'M',  'i' xor 'M',  'n' xor 'M',  'g' xor 'M', 0
 password db 'l' xor 'M','g' xor 'M', 'm' xor 'M','3' xor 'M', '8' xor 'M', '1' xor 'M', '5' xor 'M', '2' xor 'M', '1' xor 'M', 0
 name_in db 100 dup(0)
 password_in db 100 dup(0)
 flag dd ? ;标志位
 len1 dd ?
 len2 dd ?
 len3 dd ?
 len4 dd ?
 TryCount dd 3
 Mychar db ?
 ;等待按键状态
 op db 100 dup(0)
 len5 dd ?
 endflag dd ? ;标志位
 ;所有用于打印or输入的字符串
 PrintForString db '%s', 0ah, 0dh, 0 ;用于打印字符串
 PrintForStruct db '%s %d %d %d %d', 0ah, 0dh, 0 ;用于打印结构体
 Welcome db 'Please input your username and password', 0 ;输入用户名与密码
 Check db 'Verifying username and password', 0 ;正在核实
 Correct db 'The username and password are correct', 0 ;正确
 Wrong db 'The username or password is incorrect, please re-enter it', 0 ;输入错误，请重新输入
 MyEnd db 'Too many attempts: The program ends', 0 ;输入错误过多，结束
 ScanfForString db '%s', 0 ;用于输入字符串
 ;动态修改执行代码
 machine_code db 0E8H, 24H, 0, 0, 0 ;注意此处的2FH
 machine_code_len = $ - machine_code
 oldprotect dd ?
 machine_code2 db 0E8H, 44H, 01H, 0, 0
 machine_code_len2 = $ - machine_code2
 oldprotect2 dd ?
 ;用于间接调用子程序
 functable dd MyMode, Login

.stack 200
.code ;代码段
 ;子程序1 求解字符串长度
 GetLen proc c, buf: dword, num:dword
 	pushad
 	mov ebx, buf
 	mov ecx, 0
 lp:
 	cmp byte ptr [ebx], 0
 	je exit
 	inc ebx
 	inc ecx
 exit:
 	mov ebx, num
 	mov [ebx], ecx
 	popad
    ret
 GetLen endp

 ;子程序2 打印MIDF
 PrintMid proc c, buf:dword, bias:dword
	local num:dword ;需要打印的数量
	;计算出需要打印的数量 即bias / sizeof SAMPLES
	mov eax, bias
	cdq ;符号扩展
	idiv SizeOfSamples
	mov num, eax 
	;进行循环
	mov ebx, 0 ;千万别用ecx,,,printf会改变ecx的值
	mov esi, buf
 lp:
	cmp ebx, num
	je exit
	;计算偏移地址
	invoke printf, offset PrintForStruct, esi, [esi].SAMPLES.SDA, [esi].SAMPLES.SDB, [esi].SAMPLES.SDC, [esi].SAMPLES.SF
	add esi, SizeOfSamples
	inc ebx
	jmp lp
 exit:
	ret
 PrintMid endp
 
 ;子程序3 用于配合子程序5实现"自我修改返回地址的子程序"
 Display proc
 	pop ebx
 PrintChar:
 	cmp byte ptr [ebx], 0
 	je DisplayExit
 	invoke putchar, byte ptr [ebx]
 	inc ebx
 	jmp PrintChar
 DisPlayExit:
 	inc ebx
 	push ebx
 	ret
 Display endp
 
 ;子程序4 选择模式
 MyMode proc c
 	call Display
 	msg1 db 'Click Q to quit, click R to redo: ', 0ah, 0dh, 0
 InputPlease:
 	invoke scanf, offset ScanfForString, offset op
 	invoke GetLen, offset op, offset len5
 	cmp len5, 1
 	je LengthOne
 	call Display
 	msg2 db 'The input is invalid', 0ah, 0dh, 0
 	jmp InputPlease
 LengthOne:
 	cmp op, 'Q'
 	je IsQ
 	cmp op, 'q'
 	je IsQ
 	cmp op, 'R'
 	je IsR
 	cmp op, 'r'
 	je IsR 
    call Display
    msg3 db 'The input is invalid',0ah, 0dh, 0
    jmp InputPlease
 IsQ:
 	call Display
 	msg4 db 'End of program', 0ah, 0dh, 0
 	mov endflag, 0
 	ret
 IsR:
 	call Display
 	msg5 db 'Choose Redo', 0ah, 0dh, 0
 	mov endflag, 1
 	ret
 MyMode endp
 
 ;子程序5 字符串比较
 ;为什么要把宏改为子程序，因为这里用了Change函数的动态修改执行代码，需要知道偏移量
 MyCom proc, Stringone:dword, Stringtwo:dword, Lens1:dword, Lens2:dword  ;注意不区分大小写 不可以重名
   mov eax, Lens1
   cmp eax, Lens2
   jne WA
   ;开始比较串
   mov edi, Stringone
   mov esi, Stringtwo
   mov ecx, 0
   mov edx, Lens1
 StringCom:
    mov al, byte ptr [edi]
    mov Mychar, al
    pushad;保存寄存器
    ;call Change ;将这个函数调用改为动态执行
    mov eax, machine_code_len
    mov ebx, 40H
    lea ecx, CopyHere
    invoke VirtualProtect, ecx, eax, ebx, offset oldprotect
    mov ecx, machine_code_len
    mov edi, offset CopyHere
    mov esi, offset machine_code
 CopyCode:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    loop CopyCode
 CopyHere:
    db machine_code_len dup(0)
    
    popad;恢复寄存器
    mov al, byte ptr [esi]
    cmp Mychar, al
    jne WA
    inc edi
    inc esi
    inc ecx
    cmp ecx, edx
    jne StringCom
    jmp ExitCom
 WA:
    mov flag, 0
    jmp ExitCom
 ExitCom:
    ret
 MyCom endp
 	
 ;子程序6用于 配合上方字符串比较函数 改为动态修改执行代码
 Change proc 
 	xor Mychar, 'M'
 	ret
 Change endp
 
 ;主程序
 main proc c
	mov eax, functable + 4
 	call eax ;间接调用Login函数
 Calc:
    mov eax, machine_code_len2
 	mov ebx, 40H
 	lea ecx, CopyHere2
 	invoke VirtualProtect, ecx, eax, ebx, offset oldprotect2
 	mov ecx, machine_code_len
 	mov edi, offset CopyHere2
 	mov esi, offset machine_code2
 CopyCode2:
 	mov al, [esi]
 	mov [edi], al
 	inc esi
 	inc edi
 	loop CopyCode2
 CopyHere2:
 	db machine_code_len2 dup(0)
 Print:
 	invoke PrintMid, offset MIDF, MidBias ;打印
 ChooseMode:
 	call MyMode ;选择模式
 	cmp endflag, 0
 	je Exit
 	jmp Calc
 Exit:
 	invoke ExitProcess, 0
 main endp
 
 ;子程序7 用户登录界面
 Login proc c
 	invoke printf, offset PrintForString, offset Welcome
 	invoke GetLen, offset names, offset len1
 	invoke GetLen, offset password, offset len2
 lp:
 	invoke scanf, offset ScanfForString, offset name_in
 	invoke scanf, offset ScanfForString, offset password_in
 	invoke GetLen, offset name_in, offset len3
 	invoke GetLen, offset password_in, offset len4
 	mov flag, 1
    invoke MyCom, offset names, offset name_in, len1, len3
 	invoke MyCom, offset password, offset password_in, len2, len4
 	cmp flag, 0
 	jne CorrectRet
 	dec TryCount
 	cmp TryCount, 0
 	je WrongExit
 	invoke printf, offset PrintForString, offset Wrong
 	jmp lp
 CorrectRet:
 	invoke printf, offset PrintForString, offset Correct
 	ret
 WrongExit:
 	invoke printf, offset PrintForString, offset MyEnd
 	invoke ExitProcess, 0 ;直接暴力退出
 	ret
 Login endp

  ;子程序8 计算 公式修改为
 ;计算的时候插入了一些无效指令
 Calcoptimize proc c
	mov SizeOfSamples, sizeof SAMPLES
	mov esi, offset INPUT ;用esi存放结构体数组的起始地址
	mov ecx, 5 ;和上面的n一个值
 lp:
	mov eax, [esi].SAMPLES.SDA
	mov ebx, 10 ;无效指令1
	lea eax, 22[eax][eax * 4]
	add eax, [esi].SAMPLES.SDB
	add ebx, eax ;无效指令2
	sub eax, [esi].SAMPLES.SDC
	sar eax, 6 ;改成算术右移
	xor edx, 10; 无效指令3
	mov [esi].SAMPLES.SF, eax
	cmp eax, 64H
	jg L1
	jl L2
	;把数据存进去MID
	mov ebx, offset MIDF
	add ebx, MidBias
	add MidBias, sizeof SAMPLES
	jmp action
	mov eax, 10 ;无效指令4
	mov ebx, 20 ;无效指令5
	mov edx, SizeOfSamples ;无效指令6
 L1:
	;把数据存进去HIGH
	mov ebx, offset HIGHF
	add ebx, HighBias
	add HighBias, sizeof SAMPLES
	jmp action
 L2:
	;把数据存进去LOW
	mov ebx, offset LOWF 
	add ebx, LowBias
	add LowBias, sizeof SAMPLES
	jmp action
 action:
	mov eax, dword ptr [esi] ;前4个字节
	mov dword ptr [ebx], eax
	mov ax, word ptr 4[esi] ;后两个字节
	mov word ptr 4[ebx], ax
	;后面4个数字
	mov eax, [esi].SAMPLES.SDA
	mov [ebx].SAMPLES.SDA, eax
	mov eax, [esi].SAMPLES.SDB
	mov [ebx].SAMPLES.SDB, eax
	mov eax, [esi].SAMPLES.SDC
	mov [ebx].SAMPLES.SDC, eax
	mov eax, [esi].SAMPLES.SF
	mov [ebx].SAMPLES.SF, eax
	add esi, sizeof SAMPLES
	dec ecx
	cmp ecx, 0
	je L4
	jmp lp
 L4:
	ret
 Calcoptimize endp

 ;子程序10 多余的calculate函数 用于干扰
 ;该计算函数为 SF = (SDA * 9 + 100 - SDB + SDC) >> 8
 Calcoptimize2 proc c
	mov SizeOfSamples, sizeof SAMPLES
	mov esi, offset INPUT ;用esi存放结构体数组的起始地址
	mov ecx, 5 ;和上面的n一个值
 lp:
	;乘5 + 100用lea优化
	mov eax, [esi].SAMPLES.SDA
	mov ebx, 10 ;无效指令1
	lea eax, 100[eax][eax * 8]
	add eax, [esi].SAMPLES.SDB
	add ebx, eax ;无效指令2
	sub eax, [esi].SAMPLES.SDC
	sar eax, 8 ;改成算术右移
	xor edx, 10; 无效指令3
	mov [esi].SAMPLES.SF, eax
	cmp eax, 64H
	jg L1
	jl L2
	;把数据存进去MID
	mov ebx, offset MIDF
	add ebx, MidBias
	add MidBias, sizeof SAMPLES
	jmp action
	mov eax, 10 ;无效指令4
	mov ebx, 20 ;无效指令5
	mov edx, SizeOfSamples ;无效指令6
 L1:
	;把数据存进去HIGH
	mov ebx, offset HIGHF
	add ebx, HighBias
	add HighBias, sizeof SAMPLES
	jmp action
 L2:
	;把数据存进去LOW
	mov ebx, offset LOWF 
	add ebx, LowBias
	add LowBias, sizeof SAMPLES
	jmp action
 action:
	mov eax, dword ptr [esi] ;前4个字节
	mov dword ptr [ebx], eax
	mov ax, word ptr 4[esi] ;后两个字节
	mov word ptr 4[ebx], ax
	;后面4个数字
	mov eax, [esi].SAMPLES.SDA
	mov [ebx].SAMPLES.SDA, eax
	mov eax, [esi].SAMPLES.SDB
	mov [ebx].SAMPLES.SDB, eax
	mov eax, [esi].SAMPLES.SDC
	mov [ebx].SAMPLES.SDC, eax
	mov eax, [esi].SAMPLES.SF
	mov [ebx].SAMPLES.SF, eax
	add esi, sizeof SAMPLES
	dec ecx
	cmp ecx, 0
	je L4
	jmp lp
 L4:
	ret
 Calcoptimize2 endp
end