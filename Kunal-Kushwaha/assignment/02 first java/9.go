// 9. To find Armstrong Number between two given number.

package main

import (
	"fmt"
	"math"
	"strconv"
)

func main() {

	var num int
	fmt.Print("Enter a number:")
	fmt.Scan(&num)
	numbk := num
	var sumOfpower int
	var decidePow = len(strconv.Itoa(num))

	for num > 0 {
		lastDigit := num % 10
		sumOfpower += int(math.Pow(float64(lastDigit), float64(decidePow)))
		num /= 10
	}

	fmt.Println("Sum of Cube is:", sumOfpower, ", Num is:", numbk, ", decidePow is:", decidePow)
	if sumOfpower == numbk {
		fmt.Println("ArmStrong Number")
	} else {
		fmt.Println("Not Armstrong Number")
	}
}
