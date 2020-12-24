import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { CnvGenesetSurvivalComponent } from './cnv-geneset-survival.component';

describe('CnvGenesetSurvivalComponent', () => {
  let component: CnvGenesetSurvivalComponent;
  let fixture: ComponentFixture<CnvGenesetSurvivalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ CnvGenesetSurvivalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CnvGenesetSurvivalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
