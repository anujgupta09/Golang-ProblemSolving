// 1. Area Of Circle Java Program
// 2. Area Of Triangle
// 3. Area Of Rectangle Program
// 4. Area Of Isosceles Triangle
// 5. Area Of Parallelogram
// 6. Area Of Rhombus
// 7. Area Of Equilateral Triangle

package main

import "fmt"

func main() {
	var radius float32
	fmt.Scan(&radius)
	var Pi float32
	Pi = 3.14

	AreaOfCircle := Pi * float32(radius) * float32(radius)

	fmt.Println(AreaOfCircle)
}

// similarly we can do for all
