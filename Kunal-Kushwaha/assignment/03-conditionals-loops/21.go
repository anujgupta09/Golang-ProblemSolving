// 21. Fibonacci Series In Java Programs

package main

import (
	"fmt"
)

func main() {
	var c int64 = 1
	var p int64 = 0
	var n int64
	fmt.Println("Enter nth number")
	fmt.Scan(&n)
	var fiboSeries []int64
	var i int64
	for i = 1; i <= n; i++ {
		fiboSeries = append(fiboSeries, p)
		cbk := c  //as these statement is after 'append and print' last loop is not of any use
		c = c + p // but as we are giving 1st value from p directly loop of 10 is enough for generating all 10 values
		p = cbk
	}
	fmt.Println(fiboSeries, " >>>  Upto ", n, " numbers ")

}
