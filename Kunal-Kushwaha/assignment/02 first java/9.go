// 9. To find Armstrong Number between two given number.

package main

import (
	"fmt"
	"math"
	"strconv"
)

func main() {

	var num1, num2 int
	fmt.Print("Enter num1 :")
	fmt.Scan(&num1)
	fmt.Print("Enter num2 :")
	fmt.Scan(&num2)

	for i := num1; i <= num2; i++ {
		var sumOfpower int
		var decidePow = len(strconv.Itoa(i))
		var j = i
		for j > 0 {
			lastDigit := j % 10
			sumOfpower += int(math.Pow(float64(lastDigit), float64(decidePow)))
			j /= 10
		}

		if sumOfpower == i {
			fmt.Println("Sum of Cube is : ", sumOfpower, "|| Num is : ", i, " || decidePow is : ", decidePow, " || ", i, " is a Armstrong number")
		}

	}

}
