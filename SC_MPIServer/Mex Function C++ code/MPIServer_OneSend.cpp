#include "mex.hpp"
#include "mexAdapter.hpp"

using namespace matlab::data;
using matlab::mex::ArgumentList;

extern "C"
{
    void MPIServer_OneSend(int *iT, float *msg, int *ierror);
}

class MexFunction : public matlab::mex::Function
{
    std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
    ArrayFactory factory;
    std::ostringstream stream;

public:
    void operator()(ArgumentList outputs, ArgumentList inputs)
    {
        int ierror = 0;
        int iT = inputs[0][0];

        TypedArray<float> inputArr = inputs[1];
        buffer_ptr_t<float> bPtr = inputArr.release();
        float * ptr = bPtr.get();
        
        MPIServer_OneSend(&iT, ptr, &ierror);

        if (ierror != 0)
        {
            stream << "An error occured in MPIServer_OneSend, code: " << ierror  << "\n";
            displayOnMATLAB(stream);
        }

        outputs[0] = factory.createArrayFromBuffer<float>(inputArr.getDimensions(), std::move(bPtr));
    }

    void displayOnMATLAB(std::ostringstream &stream)
    {
        // Pass stream content to MATLAB fprintf function
        matlabPtr->feval(u"fprintf", 0,
                         std::vector<Array>({factory.createScalar(stream.str())}));
        // Clear stream buffer
        stream.str("");
    }
};