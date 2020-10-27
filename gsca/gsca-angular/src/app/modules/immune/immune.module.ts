import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { ImmuneRoutingModule } from './immune-routing.module';
import { ImmuneComponent } from './immune.component';
import { SharedModule } from 'src/app/shared/shared.module';

@NgModule({
  declarations: [ImmuneComponent],
  imports: [CommonModule, ImmuneRoutingModule, SharedModule],
})
export class ImmuneModule {}
