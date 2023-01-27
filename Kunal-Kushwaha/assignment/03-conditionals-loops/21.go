// 21. Fibonacci Series In Java Programs

package main

import (
	"fmt"
)

func main() {
	var c float64 = 1
	var p float64 = 0
	var n float64
	fmt.Println("Enter nth number")
	fmt.Scan(&n)
	var fiboSeries []float64
	var i float64
	for i = 1; i <= n; i++ {
		fiboSeries = append(fiboSeries, p)
		cbk := c  //as these statement is after 'append and print' last loop is not of any use
		c = c + p // but as we are giving 1st value from p directly loop of 10 is enough for generating all 10 values
		p = cbk
	}
	fmt.Println(fiboSeries, " >>>  Upto ", n, " numbers ")

}
