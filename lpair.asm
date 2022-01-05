.model small
.stack
.data
maxlen  db 11h
actlen  db ?
nmbuf   db 11h dup(0)

numa    dd 0
numb    dd 0
ans     dd 0
crlf    db 0dh,0ah,'$'
.code
start:  mov ax,@data;设置数据段地址
        mov ds,ax

        call read;读入n，存入numa
        lea si,numa
        mov [si],ax
        mov [si+2],dx
        
        call read;读入m
        lea si,numa
        ;比较dx_ax和numa的大小，也就是m和n的大小
        cmp dx,[si+2];比较高位
        ja bbig;高位大于，说明后读入的大
        jb abig;高位小于，说明先读入的大
        cmp ax,[si];高位等于，比较低位
        ja bbig;低位大于，说明后读入的大
        jmp abig;否则认为先读入的大

abig:   xchg [si],ax;先读入的大，交换dx_ax和numa
        xchg [si+2],dx
bbig:   lea si,numb;dx_ax放入numb
        mov [si],ax
        mov [si+2],dx

        call solve;调用循环模块运行算法

        mov ax,4c00h;结束程序
        int 21h
solve proc near;算法主体部分，求[numa,numb]之间的亲密数对
        lea si,numa;dx_ax存储numa
        mov ax,[si]
        mov dx,[si+2]
lp2:
        call getd;求当前dx_ax的因数和

        lea si,ans;读入因数和存储到cx_bx中
        mov bx,[si]
        mov cx,[si+2]
        ;判断cx_bx是否大于dx_ax
        cmp cx,dx;判断高位
        jb no;高位小于，准备开始下一次循环
        ja nxt;高位大于，继续算法
        cmp bx,ax;高位等于，判断低位
        jbe no;低位小于等于，准备开始下一次循环
        ;低位大于，继续算法
nxt:    ;判断cx_bx是否小于等于numb
        lea si,numb
        cmp cx,[si+2];判断高位
        ja no;高位大于，准备开始下一次循环
        jb work;高位小于，继续算法
        cmp bx,[si];高位等于，判断低位
        ja no;低位大于，准备开始下一次循环
        ;低位小于等于，继续算法
work:   
        push ax;保存dx_ax的值，也就是当前枚举到的数字
        push dx
        mov ax,bx;cx_bx是dx_ax的因数和，cx_bx赋值到dx_ax
        mov dx,cx
        push bx;保存寄存器信息
        push cx
        call getd;求当前dx_ax的因数和
        pop cx;恢复寄存器信息
        pop bx
        ;判断ans是否和dx_ax相等
        lea si,ans
        pop dx;恢复寄存器信息
        pop ax
        cmp dx,[si+2];判断高位
        jnz no;不等，准备开始下一次循环
        cmp ax,[si];判断低位
        jnz no;不等，准备开始下一次循环
        ;相等，输出答案
        push ax;保存寄存器信息
        push dx
        
        call pr;调用输出子程序输出dx_ax
        
        mov dl,',';输出逗号分隔符
        mov ax,0200h
        int 21h
        
        mov ax,bx;cx_dx赋值到dx_ax
        mov dx,cx

        call pr;调用输出子程序输出当前的dx_ax

        lea dx,crlf;输出回车
        mov ax,0900h
        int 21h

        pop dx;恢复寄存器信息
        pop ax

no:
        lea si,numb;判断dx_ax是否等于numb
        cmp dx,[si+2];比较高位
        jnz addi;不等，开始下一次循环
        cmp ax,[si];高位相等比较低位
        jnz addi;不等，开始下一次循环
        ret;相等则子程序返回
        
addi:   add ax,1;dx_ax+1
        adc dx,0
        jmp lp2;开始下一次循环
pr proc near
    push cx;保存寄存器信息
    push bx
    mov bx,000ah;除数设为10
    call print
    pop bx;恢复寄存器信息
    pop cx
    ret
getd proc near;求dx_ax的因数和（除去本身）
        lea si,ans;用ans来存储答案
        mov word ptr [si],0001h;初值设为1
        mov word ptr [si+2],0000h
        
        mov bx,1;循环初值为2
lp:     inc bx

        push ax;保存寄存器信息
        push dx        
        mov ax,bx;求解bx*bx
        mul bx

        mov cx,dx;判断bx*bx是否已经大于dx_ax
        pop dx
        cmp cx,dx
        ja ed1;高位大于，跳转到结束操作
        jb bg1;高位小于，开始循环
        ;高位等于，开始比较低位
        mov cx,ax
        pop ax
        cmp cx,ax
        ja ed;低位大于，跳转到结束操作
        jb bg;低位小于，开始循环
        add [si],bx;低位等于，说明bx*bx==dx_ax，dx_ax是完全平方数，只统计一次bx，子程序返回
        adc word ptr [si+2],0;处理进位
        ret

bg1:    pop ax;一定注意要恢复寄存器信息
bg:     push dx;保存寄存器的信息
        push ax

        push ax;求出dx_ax除以bx的商和余数，使用和print子程序相同的方法
        mov ax,dx 
        xor dx,dx
        div bx
        mov cx,ax
        pop ax
        div bx;最终cx_ax为商，dx为余数
        
        cmp dx,0;判断余数是否为0
        jnz rt;不为零则开始下一个循环
        add [si],bx;为0则答案加入bx
        adc word ptr [si+2],0
        mov dx,cx;加入商cx_ax
        add [si],ax
        adc [si+2],dx

rt:     pop ax;恢复寄存器信息
        pop dx
        jmp lp

ed1:    pop ax;恢复寄存器信息
ed:     ret

        
read proc near ;读入一个数字，存放在dx_ax中
        push bx;保护寄存器内容

        lea dx,maxlen;读入字符串
        mov ax,0a00h
        int 21h
        lea dx,crlf;输出回车
        mov ax,0900h
        int 21h
        mov cl,actlen;读入的字符串长度为循环次数
        lea si,nmbuf;指针指向字符串头
        mov bx,000ah;bx赋值10
        xor ax,ax;清空要用到的寄存器
        xor dx,dx
nextc:  mov ch,[si];取出字符，然后-'0'
        sub ch,'0'
        ;计算dx_ax*10，需要先计算dx*10，再计算ax*10
        push ax; 计算dx*10
        mov ax,dx 
        mul bx
        mov dx,ax
        pop ax

        push cx;计算ax*10
        mov cx,dx
        mul bx 
        add dx,cx;加上dx*10
        pop cx
        add al,ch;加上之前取出的字符代表的数字
        adc ah,0;处理进位
        adc dx,0

        inc si;指针后移
        dec cl;循环次数-1
        jnz nextc;不为零继续循环
        
        cmp ax,0;特判数字为0的情况
        jnz nz
        cmp dx,0
        jnz nz
        inc ax;数字为0则加一
        
nz:     
        pop bx;恢复寄存器内容
        ret

print proc near ;将 dx_ax中的整数输出
        
        cmp ax,0; 判断是不是0，是0直接返回
        jnz down
        cmp dx,0
        jnz down
        ret

down:;dx_ax除以10，求余数和商，类似于乘法，拆解成dx除以10，dx除以10的余数作为高16位，+ax再除以10
        push ax
        mov ax,dx ;求dx除以10
        xor dx,dx
        div bx
        mov cx,ax; cx存储高16位的商，余数在dx，同时dx也是下一次除法操作的高16位，因此dx不变
        pop ax;求dx_ax除以10
        div bx
        push dx;栈存储余数
        mov dx,cx;恢复dx，dx_ax变成商

        call print;递归调用

        pop dx;恢复余数
        add dl,'0';输出余数
        mov ax,0200h
        int 21h
        ret
end start