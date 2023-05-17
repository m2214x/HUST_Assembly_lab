#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#define len 60000000 //内存拷贝长度为 60000000
char src[len],dst[len]; //源地址与目的地址
long int len1=len;extern void memorycopy(char *dst,char *src,long int len1); //声明外部函数
int main()
{
    struct timespec t1,t2; //定义初始与结束时间
    int i,j;
    //为初始地址段赋值，以便后续从该地址段读取数据拷贝
    for(i=0;i<len-1;i++) 
        {
        src[i]='a';
        }
    src[i]=0; 
    clock_gettime(CLOCK_MONOTONIC,&t1); //计算开始时间。
    memorycopy(dst,src,len1); //汇编调用，执行相应代码段。
    clock_gettime(CLOCK_MONOTONIC,&t2); //计算结束时间。
    //得出目标代码段的执行时间。
    printf("memorycopy time is %11u ns\n",t2.tv_nsec-t1.tv_nsec); 
    return 0;
}