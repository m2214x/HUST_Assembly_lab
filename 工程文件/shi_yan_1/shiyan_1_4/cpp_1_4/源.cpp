#include<cstdio>
#include<string>
#include<iostream>
using namespace std;
struct Result {
	string HIGH;
	string MID;
	string LOW;
	Result() {};
}A;
Result::Result() {
	HIGH = new string;

}
int main()
{
	int a = 0x20;
	int b = 20;
	int c = 30;
	int f = (5 * a + b - c + 100) / 128;
	if (f < 100) {
		x.HIGH.append((char*)a);
		x.HIGH.append((char*)b);
		x.HIGH.append((char*)c);
	}
}