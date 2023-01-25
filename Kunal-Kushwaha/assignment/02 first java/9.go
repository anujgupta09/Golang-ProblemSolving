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

	numbk1 := num1
	numbk2 := num2

	var sumOfpower1 int
	var sumOfpower2 int

	var decidePow1 = len(strconv.Itoa(num1))
	var decidePow2 = len(strconv.Itoa(num2))

	for num1 > 0 {
		lastDigit := num1 % 10
		sumOfpower1 += int(math.Pow(float64(lastDigit), float64(decidePow1)))
		num1 /= 10
	}
	for num2 > 0 {
		lastDigit := num2 % 10
		sumOfpower2 += int(math.Pow(float64(lastDigit), float64(decidePow2)))
		num2 /= 10
	}

	fmt.Println("Sum of Cube is:", sumOfpower1, ", Num is:", numbk1, ", decidePow is:", decidePow1)
	fmt.Println("Sum of Cube is:", sumOfpower2, ", Num is:", numbk2, ", decidePow is:", decidePow2)

	if sumOfpower1 == numbk1 {
		fmt.Println("num 1 is ArmStrong Number")
	} else {
		fmt.Println("num1 is Not Armstrong Number")
	}
	if sumOfpower2 == numbk2 {
		fmt.Println("num 2 is ArmStrong Number")
	} else {
		fmt.Println("num 2 is Not Armstrong Number")
	}
}
