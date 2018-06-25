using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace JenkinsTest.MainLib
{
    public class MainClass
    {
        public int Sum(int a, int b)
        {
            return a + b;
        }

        public int Divide(int a, int b)
        {
            if (b == 0)
            {
                throw new DivideByZeroException();
            }
            return a / b;
        }
    }
}
