// 8. Calculate Depreciation of Value
// 9. Calculate Batting Average
// 10. Calculate CGPA Java Program
// 11. Compound Interest Java Program
// 12. Calculate Average Marks

// 11. Compound Interest Java Program

package main

import "fmt"

func main() {
	var principal float64 = 100
	var interestRate float64 = 12
	var years float64 = 10

	for i := 1; float64(i) <= years; i++ {
		fmt.Println(principal, " on year ", i)
		principal += principal * interestRate / 100
	}
}
