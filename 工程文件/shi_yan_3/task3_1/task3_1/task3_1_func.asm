.686P
.model flat, c
  ;printf      proto c :vararg
  ;includelib  legacy_stdio_definitions.lib
  public calculate

.data
    llpFmt db "%s",0ah,0dh,0

.code

calculate proc
    push ebp
    mov ebp,esp
	mov eax, [ebp+8]
	imul eax,5
    mov edx, [ebp+12]
    add eax, edx
    mov edx, [ebp+16]
    sub eax, edx
    add eax, 100
    shr eax, 7
    mov esp, ebp
    pop ebp
    ret
calculate endp


    


end