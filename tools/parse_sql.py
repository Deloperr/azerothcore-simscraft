import re,sys,json
def rows(path):
    txt=open(path,encoding='utf-8',errors='replace').read()
    for m in re.finditer(r"INSERT INTO `[^`]+` VALUES\s*(.*?);\n",txt,re.S):
        body=m.group(1)
        # tokenizer for tuples
        i=0;n=len(body)
        while i<n:
            if body[i]=='(':
                i+=1;vals=[];cur='';inq=False
                while True:
                    c=body[i]
                    if inq:
                        if c=='\\': cur+=body[i+1]; i+=2; continue
                        if c=="'":
                            if i+1<n and body[i+1]=="'": cur+="'"; i+=2; continue
                            inq=False; i+=1; continue
                        cur+=c; i+=1; continue
                    if c=="'": inq=True; i+=1; continue
                    if c==',': vals.append(cur); cur=''; i+=1; continue
                    if c==')': vals.append(cur); i+=1; break
                    cur+=c; i+=1
                yield vals
            else: i+=1
