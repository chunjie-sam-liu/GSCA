import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { ImmuneRoutingModule } from './immune-routing.module';
import { ImmuneComponent } from './immune.component';
import { SharedModule } from 'src/app/shared/shared.module';
import { SearchBoxComponent } from './search-box/search-box.component';

@NgModule({
  declarations: [ImmuneComponent, SearchBoxComponent],
  imports: [CommonModule, ImmuneRoutingModule, SharedModule],
})
export class ImmuneModule {}
