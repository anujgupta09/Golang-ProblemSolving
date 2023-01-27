// 21. Fibonacci Series In Java Programs

package main

import (
	"fmt"
	"math/big"
)

func main() {
	// var c float64 = 1
	// var p float64 = 0
	// var n float64
	c := big.NewInt(1)
	p := big.NewInt(0)
	c = big.Int(12)
	var n int
	fmt.Println("Enter nth number")
	fmt.Scan(&n)
	var fiboSeries []big.Int

	var i int
	for i = 1; i <= n; i++ {
		fmt.Println("P : ", p)
		fiboSeries = append(fiboSeries, *p)
		cbk := c
		c := new(big.Int)
		fmt.Println("c : ", c)
		c.Add(c, p)
		p = cbk
	}
	// fmt.Println(fiboSeries, " >>>  Upto ", n, " numbers ")
}
