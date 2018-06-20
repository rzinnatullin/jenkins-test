using System;
using JenkinsTest.MainLib;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Shouldly;

namespace JenkinsTest.MainLib.Tests
{
    [TestClass]
    public class MainClassTest
    {
        [TestMethod]
        public void Test_Sum_PositiveValues_ReturnsPositiveSum()
        {
            // Arrange
            int a = 10;
            int b = 20;
            const int expectedResult = 30;
            var mainClass = new MainClass();

            // Act
            var result = mainClass.Sum(a, b);

            // Assert
            result.ShouldBe(expectedResult);
        }

        [TestMethod]
        public void Test_Divide_DividesOnePositiveByOtherPositive_ReturnsPositive()
        {
            // Arrange
            int a = 300;
            int b = 15;
            const int expectedResult = 20;
            var mainClass = new MainClass();

            // Act
            var result = mainClass.Divide(a, b);

            // Assert
            result.ShouldBe(expectedResult);
        }
    }
}
