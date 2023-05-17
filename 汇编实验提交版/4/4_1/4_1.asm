;  程序功能：每隔约1秒钟 显示一次当前的时间（时：分：秒）
;            按任意键结束本程序的运行
;        为了更好的展示正在运行的程序被打断，时间的显示和字符串的显示交杂在一起

;  涉及的知识点：
;  (1) 8号中断
;  (2) 扩充8号中断的中断处理程序
;  (3) 中断处理程序驻留在内存
;  (4) 获取系统当前时间
;  (5) 在屏幕指定位置显示串

.386
STACK  SEGMENT  USE16  STACK
       DB  200  DUP (0)
STACK  ENDS

CODE   SEGMENT USE16
       ASSUME CS:CODE, SS:STACK
  COUNT  DB  18
  HOUR   DB  ?, ?, ':'
  MIN    DB  ?, ?, ':'
  SEC    DB  ?, ?
  BUF_LEN = $ - HOUR
  CURSOR   DW  ?   ;光标
  OLD_INT  DW  ?, ?
  installed DB 'The interrupter is already installed','$'

; 扩充的 8号中断处理程序  
NEW08H  PROC  FAR
        PUSHF
        CALL  DWORD  PTR  OLD_INT
        DEC   COUNT
        JZ    DISP
        IRET
  DISP: MOV  COUNT,18
        STI
        PUSHA
        PUSH  DS
        PUSH  ES
        MOV   AX, CS
        MOV   DS, AX
        MOV   ES, AX

        CALL  GET_TIME

        MOV   BH, 0
        MOV   AH, 3
        INT    10H                   ; 读取光标位置 (DH,DL)=(行，列)
        MOV   CURSOR,  DX   ; 保存当前光标的位置
        MOV   DH, 0
        MOV   DL, 80 - BUF_LEN
        MOV   BP,  OFFSET  HOUR
        MOV   BH, 0
        MOV   BL, 07H
        MOV   CX, BUF_LEN
        MOV   AL, 0
        MOV   AH, 13H
        INT    10H        ;  显示时间字符
        MOV   DX, CURSOR
        MOV   AH, 2
        INT   10H            ; 设置光标位置，也即恢复到显示时间串前的位置
        POP   ES
        POP   DS
        POPA
        IRET
NEW08H  ENDP

GET_TIME  PROC
        MOV   AL, 4
        OUT   70H, AL
        JMP    $+2
        IN     AL, 71H
        MOV   AH,AL
        AND    AL,0FH
        SHR     AH, 4
        ADD    AX, 3030H
        XCHG  AH,  AL
        MOV   WORD PTR HOUR, AX
        MOV    AL, 2
        OUT    70H, AL
        JMP    $+2
        IN       AL, 71H
        MOV   AH, AL
        AND   AL, 0FH
        SHR   AH, 4
        ADD   AX, 3030H
        XCHG  AH, AL
        MOV   WORD PTR MIN, AX
        MOV   AL, 0
        OUT   70H, AL
        JMP    $+2
        IN       AL,  71H
        MOV   AH,  AL
        AND   AL,  0FH
        SHR    AH,  4
        ADD    AX,  3030H
        XCHG  AH,  AL
        MOV   WORD PTR SEC, AX
        RET
GET_TIME ENDP

DELAY   PROC
        PUSH  ECX
        MOV   ECX,0
L1:     INC   ECX
        CMP   ECX, 0FFFFFH
        JB    L1
        POP   ECX
        RET
DELAY   ENDP

GET_SET_INTR8_ADDRESS  PROC
        MOV   AX, 3508H
        INT   21H
        MOV   OLD_INT,  BX
        
        ; sub OLD_INT,2
        ; cmp word ptr [OLD_INT],1
        ; jz EXIT3
        ; add OLD_INT,2
        MOV   OLD_INT+2, ES

        MOV   DX, OFFSET NEW08H
        MOV   AX, 2508H
        INT   21H
        RET
GET_SET_INTR8_ADDRESS  ENDP

RESIDULE_INTR8      PROC
    ;       将新的中断处理程序驻留内存
        MOV   DX, OFFSET DELAY+15
        MOV   CL, 4
        SHR   DX, CL
        ADD   DX, 10H
        ADD   DX, 70H
        MOV   AL, 0
        MOV   AH, 31H
        INT   21H

RESIDULE_INTR8   ENDP

BEGIN:   
    PUSH  CS
    POP   DS
    MOV AX,3508H
    INT 21H
    CMP BX,OFFSET NEW08H
    JNE NEXT
    LEA DX,installed
    MOV AH,9
    INT 21h
    JMP EXIT2



NEXT:                                  
    CALL   GET_SET_INTR8_ADDRESS                                    
DISP_CHARS:
        CMP   AL, 0   
        JNZ    EXIT2
        JMP DISP_CHARS
EXIT2:
       CALL    RESIDULE_INTR8 
CODE    ENDS
        END  BEGIN
