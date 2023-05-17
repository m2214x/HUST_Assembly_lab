.686P
.model flat, stdcall
ExitProcess proto stdcall : dword
printf proto c : ptr sbyte, : vararg
includelib kernel32.lib
includelib libcmt.lib
includelib legacy_stdio_definitions.lib

.data
SAMID db '000001', 0, 0
SDA dd 80H
SDB dd 0
SDC dd 0
SF dd ?
LOWF db 24 dup(? )
MIDF db 24 dup(? )
HIGHF db 24 dup(? )
lpFmt db "%d", 0ah, 0bh, 0
output1 db "%d, trasferred to LOWF. ", 0
output2	db "%d, trasferred to MIDF. ", 0
output3	db "%d, trasferred to HIGHF. ", 0
.stack 200

.code

of_no_consider proc c
mov edx, 0
mov eax, SDA
mov ebx, 5
imul ebx; 乘法，进行扩展
add eax, SDB
sub eax, SDC
add eax, 64H; 64H是十进制的100
mov ebx, 80H; 80H是十进制的128
idiv ebx; 除法，不需要考虑符号扩展了
mov SF, eax
invoke printf, offset lpFmt, SF
cmp SF, 64H; 64H是十进制的100
jg L1
jl L2
; 把数据存入
mov edx, offset MIDF
invoke	printf, offset output2, SF
jmp action
L1 :
mov edx, offset HIGHF
invoke	printf, offset output3, SF
jmp action
L2 :
mov edx, offset LOWF
invoke	printf, offset output1, SF
jmp action
action :
	mov ecx, 0
	mov eax, dword ptr SAMID
	mov[edx][ecx], eax
	add ecx, 4
	mov eax, dword ptr[SAMID] + 4
	mov[edx][ecx], eax
	add ecx, 4
	mov eax, SDA
	mov[edx][ecx], eax
	add ecx, 4
	mov eax, SDB
	mov[edx][ecx], eax
	add ecx, 4
	mov eax, SDC
	mov[edx][ecx], eax
	add ecx, 4
	mov eax, SF
	mov[edx][ecx], eax
ret
of_no_consider endp


of_consider proc c
mov edx, 0
mov eax, SDA
mov ebx, 5
imul ebx; 乘法，进行扩展
add eax, SDB
adc edx, 0
mov ecx, SDC
imul ecx, -1
add eax, ecx
adc edx, 0
add eax, 64H; 64H是十进制的100
adc edx, 0
mov ebx, 80H; 80H是十进制的128
idiv ebx; 除法，不需要考虑符号扩展了
mov SF, eax
cmp SF, 64H; 64H是十进制的100
jg L1
jl L2
; 把数据存入
mov edx, offset MIDF
invoke	printf, offset output2, SF
jmp action
L1 :
mov edx, offset HIGHF
invoke	printf, offset output3, SF
jmp action
L2 :
mov edx, offset LOWF
invoke	printf, offset output1, SF
jmp action
action :
mov ecx, 0
mov eax, dword ptr SAMID
mov[edx][ecx], eax
add ecx, 4
mov eax, dword ptr[SAMID] + 4
mov[edx][ecx], eax
add ecx, 4
mov eax, SDA
mov[edx][ecx], eax
add ecx, 4
mov eax, SDB
mov[edx][ecx], eax
add ecx, 4
mov eax, SDC
mov[edx][ecx], eax
add ecx, 4
mov eax, SF
mov[edx][ecx], eax
ret
of_consider endp


main proc c
call of_no_consider
call of_consider
invoke ExitProcess, 0
main endp

end
