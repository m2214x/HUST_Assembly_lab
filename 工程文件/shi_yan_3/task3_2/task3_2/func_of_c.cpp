#include<stdio.h>
#include<string.h>

struct SAMPLE2 {
	char SAMID[8];
	int SDA, SDB, SDC, SF;
};

extern "C" void check(char *name, char*pass,int &flag) {
	char s1[20],s2[20];
	int x = 3;
	flag = 0;
	while (x--) {
		printf("Welcome to this lab! Please input the username and your password(Enter to trans):\n");
		scanf("%s%s", s1, s2);
		if (!strcmp(s1, name) && !strcmp(s2, pass)) {
			printf("YES! Let''s start our travel!\n");
			flag = 1;
			return;
		}
		else printf("Wrong information! Please input again!\n");
	}
	printf("You have tried three times but all were wrong, now quit.\n");
}

extern "C" void printMID(struct SAMPLE2* s,int midcap) {
	midcap /= 24;
	for (int i = 0; i < midcap; i++) {
		printf("SAMID:%s\n", s[i].SAMID);
		printf("SDA:%d\n", s[i].SDA);
		printf("SDB:%d\n", s[i].SDB);
		printf("SDC:%d\n", s[i].SDC);
		printf("SF:%d\n", s[i].SF);
	}

}

extern "C" void override(struct SAMPLE2* s) {
	printf("Please input the infoemation:(SAMID,SDA,SDB,SDC)(Enter to trans):\n");
	scanf("%s%d%d%d", s[0].SAMID, &s[0].SDA, &s[0].SDB, &s[0].SDC);
}

extern "C" void ifrestart(struct SAMPLE2* s,int &model) {
	printf("Now all done. Click r to restart, click q to quit, or click m to override the first SAMPLE:");
	char x;
	while (1) {
		getchar();
		x = getchar();
		switch (x)
		{
		case 'q':
			model = 0;
			return;
		case 'r':
			model = 1;
			return;
		case'm':
			override(s);
			break;
		default:
			printf("Input error! Please try again(click q to quit, or click m to override the first SAMPLE):");
			break;
		}
	}
	
}