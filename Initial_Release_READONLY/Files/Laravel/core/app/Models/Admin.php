<?php

namespace App\Models;

use App\Traits\GlobalStatus;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Spatie\Permission\Traits\HasRoles;

class Admin extends Authenticatable
{
    use GlobalStatus, HasRoles;
    /**
     * The attributes that should be hidden for arrays.
     *
     * @var array
     */
    protected $casts = [
        'status' => 'integer',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];



    public function imageSrc(): Attribute
    {
        return new Attribute(
            get: fn() => $this->image  ? getImage(getFilePath('admin') . '/' . $this->image, getFileSize('admin')) : siteFavicon(),
        );
    }

    public function activities()
    {
        return $this->hasMany(AdminActivity::class);
    }
}
