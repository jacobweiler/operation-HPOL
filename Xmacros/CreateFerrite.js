// ferrite function defintion
function CreateFerrite()
{

    var mSampled = new MagneticSampledParameters()

    mSampled.addFrequency("1 GHz", 1,0)

    var ferrite = new Material();

    ferrite.name = "ferrite";

    var ferriteElectricIsotropic = new ElectricIsotropic();

    var ferriteMagneticIsotropic = new MagneticIsotropic(mSampled);

    var ferritePhysicalMaterial = new PhysicalMaterial();

    ferritePhysicalMaterial.setElectricProperties( ferriteElectricIsotropic );

    ferritePhysicalMaterial.setMagneticProperties( ferriteMagneticIsotropic );

    ferrite.setDetails( ferritePhysicalMaterial );

    var ferriteBodyAppearance = ferrite.getAppearance();

    var ferriteFaceAppearance = ferriteBodyAppearance.getFaceAppearance();

    ferriteFaceAppearance.setColor( new Color( 200, 100, 200, 200) );

    if(null != App.getActiveProject().getMaterialList().getMaterial(ferrite.name) )
    {
        App.getActiveProject().getMaterialList().removeMaterial(ferrite.name);
    }

    App.getActiveProject().getMaterialList().addMaterial( ferrite );

}