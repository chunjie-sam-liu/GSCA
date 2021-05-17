import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocMethySurvivalComponent } from './doc-methy-survival.component';

describe('DocMethySurvivalComponent', () => {
  let component: DocMethySurvivalComponent;
  let fixture: ComponentFixture<DocMethySurvivalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocMethySurvivalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocMethySurvivalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
