data <- as.data.frame(cds@scale.data[c("esg","Mip"),])
data[1:2,1:5]
gate <- as.data.frame(t(apply(data, 2, function(x)ifelse(x > 0.5,1,0))))
head(gate)
mytable
mytable <- table(gate)
chisq.test(mytable)
fisher.test(mytable)

library(vcd)
assocstats(mytable)



data2 <- as.data.frame(cds@scale.data[c("mirr","Tk"),])
data2[1:2,1:5]
gate2 <- as.data.frame(t(apply(data2, 2, function(x)ifelse(x > 0.5,x,0))))
gate2[1:5,]
library(dplyr)
mutate(gate2,mirr*Tk)
data_final <- gate2[ifelse(gate2$mirr*gate2$Tk == 0,FALSE,TRUE),]
head(data_final)
cor(data_final)
plot(data_final$mirr,data_final$Tk)

data3 <- as.data.frame(t(as.matrix(cds@data[c("mirr","Tk"),])))
data3[1:5,]
plot(data3$mirr,data3$Tk)
cor(data3)


data3 <- as.data.frame(t(as.matrix(cds@raw.data[c("mirr","Tk"),])))
data3[1:5,]
plot(data3$mirr,data3$Tk)
cor(data3)

library(psych)
describeBy(data3$Tk,list(mirr = data3$mirr))

